
use wca::*;
use wtest_basic::*;
use std::collections::HashMap;

//

fn _basic()
{
  let instruction = instruction::Instruction::default();
  let exp = instruction::Instruction
  {
    err : None,
    command_name : "".to_string(),
    subject : "".to_string(),
    properties_map : HashMap::new(),
  };
  assert_eq!( instruction, exp );
}

//

test_suite!
{
  basic,
}
