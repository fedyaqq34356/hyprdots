use crate::util::home;
use serde_json::{json, Value};
use std::collections::HashMap;
use std::fs;
use std::io::{Read, Write};
use std::net::TcpStream;
use std::os::unix::fs::MetadataExt;
use std::os::unix::net::UnixStream;
use std::time::Duration;

const T: Duration = Duration::from_secs(3);

type Group = HashMap<String, Vec<(u8, Vec<u8>)>>;

fn user() -> String {
    let pw = unsafe { libc::getpwuid(libc::getuid()) };
    if pw.is_null() {
        return std::env::var("USER").unwrap_or_else(|_| "anonymous".into());
    }
    unsafe { std::ffi::CStr::from_ptr((*pw).pw_name) }.to_string_lossy().into_owned()
}

struct Req(Vec<u8>);

impl Req {
    fn new(op: u16) -> Req {
        let mut r = Req(vec![2, 0]);
        r.0.extend(op.to_be_bytes());
        r.0.extend(1u32.to_be_bytes());
        r.0.push(0x01);
        r.attr(0x47, "attributes-charset", &["utf-8"]);
        r.attr(0x48, "attributes-natural-language", &["en"]);
        r
    }

    fn attr(&mut self, tag: u8, name: &str, vals: &[&str]) -> &mut Req {
        for (i, v) in vals.iter().enumerate() {
            let n = if i == 0 { name } else { "" };
            self.0.push(tag);
            self.0.extend((n.len() as u16).to_be_bytes());
            self.0.extend(n.as_bytes());
            self.0.extend((v.len() as u16).to_be_bytes());
            self.0.extend(v.as_bytes());
        }
        self
    }

    fn done(mut self) -> Vec<u8> {
        self.0.push(0x03);
        self.0
    }
}

trait Io: Read + Write {}
impl<S: Read + Write> Io for S {}

fn connect() -> Option<Box<dyn Io>> {
    let mut socks: Vec<String> = vec![];
    if let Ok(s) = std::env::var("CUPS_SERVER") {
        if s.starts_with('/') {
            socks.push(s);
        }
    }
    socks.extend(["/run/cups/cups.sock".into(), "/var/run/cups/cups.sock".into()]);
    for s in socks {
        if let Ok(u) = UnixStream::connect(&s) {
            u.set_read_timeout(Some(T)).ok()?;
            u.set_write_timeout(Some(T)).ok()?;
            return Some(Box::new(u));
        }
    }
    let t = TcpStream::connect_timeout(&"127.0.0.1:631".parse().ok()?, T).ok()?;
    t.set_read_timeout(Some(T)).ok()?;
    t.set_write_timeout(Some(T)).ok()?;
    Some(Box::new(t))
}

fn ipp(body: Vec<u8>) -> Option<Vec<Group>> {
    let mut s = connect()?;
    let head = format!(
        "POST / HTTP/1.0\r\nHost: localhost\r\nContent-Type: application/ipp\r\nContent-Length: {}\r\n\r\n",
        body.len()
    );
    s.write_all(head.as_bytes()).ok()?;
    s.write_all(&body).ok()?;
    let mut buf = vec![];
    s.read_to_end(&mut buf).ok()?;
    let split = buf.windows(4).position(|w| w == b"\r\n\r\n")?;
    let status = std::str::from_utf8(&buf[..split]).ok()?.lines().next()?.split_whitespace().nth(1)?.to_string();
    if status != "200" {
        return None;
    }
    parse(&buf[split + 4..])
}

fn parse(b: &[u8]) -> Option<Vec<Group>> {
    if b.len() < 8 {
        return None;
    }
    if u16::from_be_bytes([b[2], b[3]]) >= 0x0100 {
        return Some(vec![]);
    }
    let mut groups: Vec<(u8, Group)> = vec![];
    let mut i = 8;
    let mut last = String::new();
    while i < b.len() {
        let tag = b[i];
        i += 1;
        if tag == 0x03 {
            break;
        }
        if tag < 0x10 {
            groups.push((tag, Group::new()));
            continue;
        }
        let nl = u16::from_be_bytes([*b.get(i)?, *b.get(i + 1)?]) as usize;
        let name = std::str::from_utf8(b.get(i + 2..i + 2 + nl)?).ok()?.to_string();
        i += 2 + nl;
        let vl = u16::from_be_bytes([*b.get(i)?, *b.get(i + 1)?]) as usize;
        let val = b.get(i + 2..i + 2 + vl)?.to_vec();
        i += 2 + vl;
        if !name.is_empty() {
            last = name;
        }
        if let Some((_, g)) = groups.last_mut() {
            g.entry(last.clone()).or_default().push((tag, val));
        }
    }
    Some(groups.into_iter().filter(|(t, _)| *t == 0x02 || *t == 0x04).map(|(_, g)| g).collect())
}

fn s(g: &Group, k: &str) -> String {
    g.get(k).and_then(|v| v.first()).map(|v| String::from_utf8_lossy(&v.1).into_owned()).unwrap_or_default()
}

fn int(g: &Group, k: &str) -> Option<i64> {
    let v = &g.get(k)?.first()?.1;
    match v.len() {
        4 => Some(i32::from_be_bytes(v[..4].try_into().ok()?) as i64),
        1 => Some(v[0] as i64),
        _ => None,
    }
}

fn lpoptions_default() -> Option<String> {
    for v in ["LPDEST", "PRINTER"] {
        match std::env::var(v) {
            Ok(p) if !p.is_empty() && !(v == "PRINTER" && p == "lp") => return Some(p),
            _ => {}
        }
    }
    for f in [home().join(".cups/lpoptions"), "/etc/cups/lpoptions".into()] {
        let Ok(t) = fs::read_to_string(f) else { continue };
        for l in t.lines() {
            let mut w = l.split_whitespace();
            if w.next().is_some_and(|k| k.eq_ignore_ascii_case("default")) {
                if let Some(n) = w.next() {
                    return Some(n.split('/').next().unwrap_or(n).to_string());
                }
            }
        }
    }
    None
}

fn strftime_c(t: i64) -> String {
    let t = t as libc::time_t;
    let mut tm: libc::tm = unsafe { std::mem::zeroed() };
    unsafe { libc::localtime_r(&t, &mut tm) };
    let mut buf = [0u8; 128];
    let n = unsafe { libc::strftime(buf.as_mut_ptr().cast(), buf.len(), c"%c".as_ptr(), &tm) };
    String::from_utf8_lossy(&buf[..n]).into_owned()
}

fn ccpd_pid() -> Option<u32> {
    fs::read_dir("/proc")
        .ok()?
        .flatten()
        .filter_map(|e| e.file_name().to_str()?.parse::<u32>().ok())
        .filter(|pid| fs::read_to_string(format!("/proc/{pid}/comm")).is_ok_and(|c| c.trim() == "ccpd"))
        .max()
}

fn status() -> Value {
    let me = user();
    let attrs = ["printer-name", "printer-state", "printer-state-message", "device-uri", "printer-is-accepting-jobs"];
    let mut r = Req::new(0x4002);
    r.attr(0x42, "requesting-user-name", &[&me]).attr(0x44, "requested-attributes", &attrs);
    let Some(groups) = ipp(r.done()) else {
        return json!({"cups": false, "capt": {"needed": false}, "printers": [], "jobs": []});
    };

    let default = lpoptions_default().or_else(|| {
        let mut r = Req::new(0x4001);
        r.attr(0x44, "requested-attributes", &["printer-name"]);
        ipp(r.done())?.first().map(|g| s(g, "printer-name")).filter(|n| !n.is_empty())
    });

    let mut capt_needed = false;
    let mut printers = vec![];
    for g in &groups {
        let name = s(g, "printer-name");
        if name.is_empty() {
            continue;
        }
        let uri = s(g, "device-uri");
        let capt = uri.starts_with("ccp://");
        capt_needed |= capt;
        let st = match int(g, "printer-state") {
            Some(3) => "idle",
            Some(4) => "printing",
            Some(5) => "stopped",
            _ => "unknown",
        };
        printers.push(json!({
            "name": name,
            "state": st,
            "reason": s(g, "printer-state-message"),
            "uri": uri,
            "capt": capt,
            "accepting": int(g, "printer-is-accepting-jobs") == Some(1),
            "default": default.as_deref() == Some(name.as_str()),
        }));
    }

    let mut r = Req::new(0x000A);
    r.attr(0x45, "printer-uri", &["ipp://localhost/"])
        .attr(0x42, "requesting-user-name", &[&me])
        .attr(0x44, "which-jobs", &["not-completed"])
        .attr(
            0x44,
            "requested-attributes",
            &["job-id", "job-printer-uri", "job-originating-user-name", "job-k-octets", "time-at-creation"],
        );
    let mut jobs = vec![];
    for g in ipp(r.done()).unwrap_or_default() {
        let Some(id) = int(&g, "job-id") else { continue };
        let dest = s(&g, "job-printer-uri");
        let dest = dest.rsplit('/').next().unwrap_or("");
        jobs.push(json!({
            "id": format!("{dest}-{id}"),
            "user": s(&g, "job-originating-user-name"),
            "size": int(&g, "job-k-octets").unwrap_or(0) * 1024,
            "when": int(&g, "time-at-creation").map(strftime_c).unwrap_or_default(),
        }));
    }

    let mut lps: Vec<String> = fs::read_dir("/dev/usb")
        .map(|rd| {
            rd.flatten()
                .map(|e| e.file_name().to_string_lossy().into_owned())
                .filter(|n| n.starts_with("lp"))
                .collect()
        })
        .unwrap_or_default();
    lps.sort();
    let dev = lps.first().map(|n| format!("/dev/usb/{n}")).unwrap_or_default();
    let pid = ccpd_pid();
    let stale = match (dev.is_empty(), pid) {
        (false, Some(p)) => {
            let dev_age = fs::metadata(&dev).map(|m| m.ctime()).unwrap_or(0);
            let pid_age = fs::metadata(format!("/proc/{p}")).map(|m| m.ctime()).unwrap_or(0);
            pid_age < dev_age
        }
        _ => false,
    };

    json!({
        "cups": true,
        "default": default.unwrap_or_default(),
        "capt": {"needed": capt_needed, "device": dev, "daemon": pid.is_some(), "stale": stale},
        "printers": printers,
        "jobs": jobs,
    })
}

fn ccp_port() -> u16 {
    fs::read_to_string("/etc/ccpd.conf")
        .ok()
        .and_then(|t| {
            let i = t.find("UI_Port")?;
            let rest = t[i + 7..].trim_start();
            let end = rest.find(|c: char| !c.is_ascii_digit()).unwrap_or(rest.len());
            rest[..end].parse().ok()
        })
        .unwrap_or(59787)
}

fn lstr(out: &mut Vec<u8>, b: &[u8]) {
    out.extend((b.len() as u32).to_le_bytes());
    out.extend(b);
}

fn ccp_request(cmd: u32, printer: &[u8], extra: &[u8]) -> Vec<u8> {
    let mut body = vec![];
    lstr(&mut body, printer);
    lstr(&mut body, b"en_GB.UTF-8");
    body.extend(extra);
    let mut out = b"ccp0".to_vec();
    out.extend(cmd.to_le_bytes());
    out.extend((body.len() as u32).to_le_bytes());
    out.extend(body);
    out
}

fn ccp_exchange(s: &mut TcpStream, payload: &[u8]) -> Result<(u32, Vec<u8>), String> {
    s.write_all(payload).map_err(|e| e.to_string())?;
    let mut head = [0u8; 12];
    s.read_exact(&mut head).map_err(|_| "демон закрыл соединение".to_string())?;
    if &head[..4] != b"ccp1" {
        return Err(format!("чужой ответ: {:?}", String::from_utf8_lossy(&head[..4])));
    }
    let kind = u32::from_le_bytes(head[4..8].try_into().unwrap());
    let len = u32::from_le_bytes(head[8..12].try_into().unwrap()) as usize;
    let mut body = vec![0u8; len];
    s.read_exact(&mut body).map_err(|_| "демон закрыл соединение".to_string())?;
    Ok((kind, body))
}

fn unescape(t: &str) -> String {
    t.replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&apos;", "'")
        .replace("&amp;", "&")
}

fn child(xml: &str, tag: &str) -> String {
    let open = format!("<{tag}>");
    let Some(a) = xml.find(&open) else { return String::new() };
    let rest = &xml[a + open.len()..];
    let end = rest.find(&format!("</{tag}>")).unwrap_or(0);
    unescape(&rest[..end])
}

fn alerts(xml: &[u8]) -> Vec<Value> {
    let x = String::from_utf8_lossy(xml);
    let mut out = vec![];
    for part in x.split("<PrtAlertEntry>").skip(1) {
        let entry = part.split("</PrtAlertEntry>").next().unwrap_or("");
        let code = child(entry, "PrtAlertCode").trim().to_string();
        if code.is_empty() {
            continue;
        }
        out.push(json!({
            "code": code,
            "severity": child(entry, "PrtAlertSeverityLevel").trim(),
            "text": child(entry, "PrtAlertDescription").split_whitespace().collect::<Vec<_>>().join(" "),
        }));
    }
    out
}

fn capt(printer: &str) -> Value {
    let fail = |code: &str, msg: String| json!({"ok": false, "code": code, "error": msg});
    if printer.is_empty() {
        return fail("noprinter", "принтер не указан".into());
    }
    let port = ccp_port();
    let addr = std::net::SocketAddr::from(([127, 0, 0, 1], port));
    let mut s = match TcpStream::connect_timeout(&addr, T) {
        Ok(s) => s,
        Err(e) => return fail("nodaemon", format!("ccpd не отвечает на порту {port}: {e}")),
    };
    let _ = s.set_read_timeout(Some(T));
    let _ = s.set_write_timeout(Some(T));
    let mut hello = 4u32.to_le_bytes().to_vec();
    hello.extend(0u32.to_le_bytes());
    let r = ccp_exchange(&mut s, &ccp_request(0x13, printer.as_bytes(), &hello))
        .and_then(|_| ccp_exchange(&mut s, &ccp_request(0x01, printer.as_bytes(), &0u32.to_le_bytes())));
    let (kind, body) = match r {
        Ok(x) => x,
        Err(e) => return fail("protocol", format!("обмен не удался: {e}")),
    };
    let list = alerts(&body);
    let first = list.first().cloned().unwrap_or(json!({}));
    json!({
        "ok": true,
        "port": port,
        "kind": kind,
        "code": first.get("code").cloned().unwrap_or(json!("")),
        "text": first.get("text").cloned().unwrap_or(json!("")),
        "alerts": list,
    })
}

pub fn run(args: &[String]) {
    let v = match args.first().map(String::as_str) {
        Some("capt") => capt(args.get(1).map(String::as_str).unwrap_or("")),
        _ => status(),
    };
    println!("{v}");
}
