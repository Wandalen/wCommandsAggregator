
// use wca::*;
// use maplit::hashmap;

//

#[test]
fn instructions_parse()
{

  let instructions_str = ".command1 subject1 param1:val1 param2:val2 .command2 subject2 param3:val3";
  assert_eq!( instructions_str, instructions_str );

  // let aggregator = CommandOptions::default()
  // .hint( "hint" )
  // .long_hint( "long_hint" )
  // .phrase( "phrase" )
  // .subject_hint( "subject_hint" )
  // .property_hint( "prop1", "hint of prop1" )
  // .property_hint( "prop2", "hint of prop2" )
  // .property_alias( "property_alias", "a1" )
  // .property_alias( "property_alias", "a2" )
  // .routine( &|| { println!( "hello" ) } )
  // .form()
  // ;

  // dbg!( &aggregator );

  // assert_eq!( aggregator.hint, "hint".to_string() );
  // assert_eq!( aggregator.long_hint, "long_hint".to_string() );
  // assert_eq!( aggregator.phrase, "phrase".to_string() );
  // assert_eq!( aggregator.subject_hint, "subject_hint".to_string() );

  // let properties_hints = hashmap!
  // {
  //   "prop1".to_string() => "hint of prop1".to_string(),
  //   "prop2".to_string() => "hint of prop2".to_string(),
  // };
  // assert_eq!( aggregator.properties_hints, properties_hints );

  // let properties_aliases = hashmap!
  // {
  //   "property_alias".to_string() => vec![ "a1".to_string(), "a2".to_string() ],
  // };
  // assert_eq!( aggregator.properties_aliases, properties_aliases );

}
