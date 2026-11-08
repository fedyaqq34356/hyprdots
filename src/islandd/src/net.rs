use crate::util::emit;
use dbus::blocking::stdintf::org_freedesktop_dbus::Properties;
use dbus::blocking::Connection;
use dbus::Path;
use serde_json::{json, Value};
use std::time::{Duration, Instant};

const NM: &str = "org.freedesktop.NetworkManager";
const DEV: &str = "org.freedesktop.NetworkManager.Device";
const WIFI: &str = "org.freedesktop.NetworkManager.Device.Wireless";
const AP: &str = "org.freedesktop.NetworkManager.AccessPoint";
const ACTIVE: &str = "org.freedesktop.NetworkManager.Connection.Active";
const T: Duration = Duration::from_millis(1500);
const ACTIVATED: u32 = 100;

struct Net<'a> {
    c: &'a Connection,
}

impl Net<'_> {
    fn get<R: for<'b> dbus::arg::Get<'b> + 'static>(&self, path: &Path, iface: &str, prop: &str) -> Option<R> {
        self.c.with_proxy(NM, path.clone(), T).get(iface, prop).ok()
    }

    fn state(&self) -> Value {
        let root = Path::from("/org/freedesktop/NetworkManager");
        let radio: bool = self.get(&root, NM, "WirelessEnabled").unwrap_or(false);
        let devices: Vec<Path> = self.get(&root, NM, "Devices").unwrap_or_default();

        let mut networks: Vec<(String, u8, bool, bool)> = vec![];
        let mut rate = String::new();
        let mut cur_strength = 0u8;
        let (mut wifi_iface, mut eth): (String, Option<(String, String)>) = (String::new(), None);

        for d in &devices {
            let kind: u32 = self.get(d, DEV, "DeviceType").unwrap_or(0);
            if kind != 1 && kind != 2 {
                continue;
            }
            let iface: String = self.get(d, DEV, "Interface").unwrap_or_default();
            let st: u32 = self.get(d, DEV, "State").unwrap_or(0);
            if st == ACTIVATED {
                if kind == 2 && wifi_iface.is_empty() {
                    wifi_iface = iface.clone();
                } else if kind == 1 && eth.is_none() {
                    let ac: Option<Path> = self.get(d, DEV, "ActiveConnection");
                    let name: String = ac.and_then(|a| self.get(&a, ACTIVE, "Id")).unwrap_or_default();
                    eth = Some((iface.clone(), name));
                }
            }
            if kind != 2 {
                continue;
            }
            let active_ap: Option<Path> = self.get(d, WIFI, "ActiveAccessPoint");
            let aps: Vec<Path> = self.get(d, WIFI, "AccessPoints").unwrap_or_default();
            for ap in &aps {
                let ssid: Vec<u8> = self.get(ap, AP, "Ssid").unwrap_or_default();
                if ssid.is_empty() {
                    continue;
                }
                let ssid = String::from_utf8_lossy(&ssid).into_owned();
                let strength: u8 = self.get(ap, AP, "Strength").unwrap_or(0);
                let flags: u32 = self.get(ap, AP, "Flags").unwrap_or(0);
                let wpa: u32 = self.get(ap, AP, "WpaFlags").unwrap_or(0);
                let rsn: u32 = self.get(ap, AP, "RsnFlags").unwrap_or(0);
                let active = active_ap.as_ref() == Some(ap);
                if active {
                    cur_strength = strength;
                    let max: u32 = self.get(ap, AP, "MaxBitrate").unwrap_or(0);
                    rate = if max > 0 { format!("{} Mbit/s", max / 1000) } else { String::new() };
                }
                let secured = flags & 1 != 0 || wpa != 0 || rsn != 0;
                match networks.iter_mut().find(|n| n.0 == ssid) {
                    Some(prev) => {
                        let was = prev.3 || active;
                        if strength > prev.1 {
                            *prev = (ssid, strength, secured, active);
                        }
                        prev.3 = was;
                    }
                    None => networks.push((ssid, strength, secured, active)),
                }
            }
        }
        networks.sort_by(|a, b| b.3.cmp(&a.3).then(b.1.cmp(&a.1)));
        let cur = networks.iter().find(|n| n.3);
        let list: Vec<Value> = networks
            .iter()
            .map(|n| json!({"ssid": n.0, "strength": n.1, "secured": n.2, "active": n.3}))
            .collect();
        json!({
            "radio": radio,
            "networks": list,
            "connected": cur.is_some(),
            "ssid": cur.map_or("", |n| n.0.as_str()),
            "strength": if cur.is_some() { cur_strength } else { 0 },
            "rate": if cur.is_some() { rate } else { String::new() },
            "wifiIface": wifi_iface,
            "iface": eth.as_ref().map_or(wifi_iface.clone(), |e| e.0.clone()),
            "wired": eth.is_some(),
            "wiredName": eth.as_ref().map_or(String::new(), |e| e.1.clone()),
        })
    }
}

pub fn run() {
    let Ok(conn) = Connection::new_system() else { std::process::exit(1) };
    let rules = [
        "type='signal',sender='org.freedesktop.NetworkManager'".to_string(),
        "type='signal',sender='org.freedesktop.DBus',member='NameOwnerChanged',arg0='org.freedesktop.NetworkManager'"
            .to_string(),
    ];
    for r in &rules {
        if conn.add_match_no_cb(r).is_err() {
            std::process::exit(1);
        }
    }
    let net = Net { c: &conn };
    let mut last = Value::Null;
    loop {
        let s = net.state();
        if s != last {
            emit(&s);
            last = s;
        }
        let ch = conn.channel();
        match ch.blocking_pop_message(Duration::from_secs(30)) {
            Ok(Some(_)) => {
                let until = Instant::now() + Duration::from_millis(400);
                loop {
                    let left = until.saturating_duration_since(Instant::now());
                    if left.is_zero() {
                        break;
                    }
                    if ch.blocking_pop_message(left).is_err() {
                        std::process::exit(1);
                    }
                }
            }
            Ok(None) => {}
            Err(_) => std::process::exit(1),
        }
    }
}
