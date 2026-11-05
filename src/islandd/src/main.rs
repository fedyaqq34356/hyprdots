mod mouse;
mod sort;
mod sys;
mod util;
mod watch;

fn usage() -> ! {
    eprintln!("usage: islandd <sys | mouse [status|watch [-i SECS]] | sort | watch>");
    std::process::exit(2);
}

fn main() {
    unsafe {
        libc::signal(libc::SIGPIPE, libc::SIG_DFL);
    }
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.first().is_some_and(|a| a != "sort") {
        unsafe { libc::prctl(libc::PR_SET_PDEATHSIG, libc::SIGTERM) };
    }
    match args.first().map(String::as_str) {
        Some("sys") => sys::run(),
        Some("mouse") => mouse::run(&args[1..]),
        Some("sort") => sort::run(),
        Some("watch") => watch::run(),
        _ => usage(),
    }
}
