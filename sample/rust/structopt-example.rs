
/*

cargo run --example structopt-example -- -h
cargo run --example structopt-example -- .run /path v:1 r:2

*/

use std::error::Error;
use structopt::StructOpt;

fn parse_key_val<T, U>(s: &str) -> Result<(T, U), Box<dyn Error>>
where
    T: std::str::FromStr,
    T::Err: Error + 'static,
    U: std::str::FromStr,
    U::Err: Error + 'static,
{
    let pos = s.find( ':' ).unwrap();
    let key = s[..pos].parse().unwrap();
    let val = s[ pos + 1.. ].parse().unwrap();
    Ok( ( key, val ) )
}

#[derive(StructOpt, Debug)]
#[structopt( name = "CLI", version = "1.0" )]
struct Opt 
{ 
    commnad : String,
    
    path : String,

    #[structopt(parse(try_from_str = parse_key_val) )]
    command_options: Vec<(String, String)>
}

fn main() {
    let opt = Opt::from_args();
    println!( "Command: {}\nPath: {}\nOptions: {:?}", opt.commnad, opt.path, opt.command_options );
}