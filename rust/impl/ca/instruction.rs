#![ warn( missing_docs ) ]
#![ warn( missing_debug_implementations ) ]

pub use wtools::error::*;
pub use wstring_tools::string::parse as parse;
// pub use wtools::former::*;
use std::collections::HashMap;

///
/// Instruction handle.
///

#[ derive( Debug, Default, PartialEq ) ]
pub struct Instruction
{
  /// Error of Instruction forming.
  pub err : Option<Error>,
  /// Name of command
  pub command_name : String,
  /// Subject.
  pub subject : String,
  /// Properties map.
  pub properties_map : HashMap<String, String>,
}

///
/// Instruction behaviour.
///

pub trait InstructionParseParamsAdapter
{
  /// Print info about valid command format.
  fn about_command_format( &self ) -> &'static str
  {
r#"Command should start from a dot `.`.
Command can have a subject and properties.
Property is pair delimited by colon `:`.
For example: `.struct1 subject key1:val key2:val2`."#
  }
  /// Check that command name is valid.
  fn command_name_is_valid( &self ) -> bool;
  /// Parse instruction from string slice.
  fn parse_str( self, src : &str ) -> anyhow::Result<Instruction>;
}

//

impl InstructionParseParamsAdapter for Instruction
{
  fn command_name_is_valid( &self ) -> bool
  {
    self.command_name.trim().starts_with( "." )
  }
  fn parse_str( mut self, src : &str ) -> anyhow::Result<Instruction>
  {
    let ( command_name, request ) = match src.split_once( " " )
    {
      Some( entries ) => entries,
      None => ( src, "" ),
    };

    self.command_name = command_name.to_string();

    if !self.command_name_is_valid()
    {
      self.about_command_format();
      self.err = Some( Error::new( "Invalid command name" ) );
      panic!( "Invalid command name" );
    }

    let request = parse::request_parse()
    .src( request )
    .perform();

    self.subject = request.subject.clone();
    self.properties_map = request.map.clone();

    Ok( self )
  }
}

//

///
/// Get instruction from string slice.

pub fn parse_from_str( src : &str ) -> Instruction
{
  let instruction = Instruction::default();
  let instruction = instruction.parse_str( src ).unwrap();
  instruction
}

