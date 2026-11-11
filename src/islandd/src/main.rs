mod aula;
mod clip;
#[cfg(feature = "jarvis")]
mod jarvis;
mod miclock;
mod mount;
mod mouse;
mod net;
mod print;
mod remind;
mod session;
mod sort;
mod sys;
mod util;
mod watch;

fn usage() -> ! {
    eprintln!(
        "usage: islandd <sys | mouse [status|watch [-i SECS]] | sort | watch | net | aula ARGS | clip | notif-missed | wallpaper-rotate | watchdog | mic-lock | mount | print [status|capt NAME]>"
    );
    std::process::exit(2);
}

fn main() {
    unsafe {
        libc::signal(libc::SIGPIPE, libc::SIG_DFL);
    }
    let argv: Vec<String> = std::env::args().collect();
    let me = argv.first().map(|a| a.rsplit('/').next().unwrap_or(a).to_string()).unwrap_or_default();
    if me == "aulactl" {
        std::process::exit(aula::main(&argv[1..]));
    }
    #[cfg(feature = "jarvis")]
    if me == "jarvis-askpass" {
        std::process::exit(jarvis::main(&["askpass".to_string()]));
    }
    let args = &argv[1..];
    let mode = args.first().map(String::as_str);
    if matches!(mode, Some("sys" | "mouse" | "watch" | "net" | "print")) {
        unsafe { libc::prctl(libc::PR_SET_PDEATHSIG, libc::SIGTERM) };
    }
    match mode {
        Some("sys") => sys::run(),
        Some("mouse") => mouse::run(&args[1..]),
        Some("sort") => sort::run(),
        Some("watch") => watch::run(),
        Some("net") => net::run(),
        Some("aula") => std::process::exit(aula::main(&args[1..])),
        Some("clip") => clip::run(&args[1..]),
        Some("notif-missed") => session::notif_missed(),
        Some("wallpaper-rotate") => session::wallpaper_rotate(),
        Some("watchdog") => session::watchdog(),
        Some("mic-lock") => miclock::run(),
        Some("mount") => mount::run(),
        Some("print") => print::run(&args[1..]),
        #[cfg(feature = "jarvis")]
        Some("jarvis") => std::process::exit(jarvis::main(&args[1..])),
        Some("gaming") => std::process::exit(if session::is_gaming() { 0 } else { 1 }),
        _ => usage(),
    }
}
