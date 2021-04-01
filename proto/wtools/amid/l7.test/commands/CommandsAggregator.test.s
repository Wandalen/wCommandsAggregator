( function _CommandsAggregator_test_s_()
{

'use strict';

if( typeof module !== 'undefined' )
{

  let _ = require( '../../../../wtools/Tools.s' );

  _.include( 'wTesting' );

  require( '../../l7/commands/CommandsAggregator.s' );

}

const _global = _global_;
const _ = _global_.wTools;

// --
// tests
// --

function trivial( test )
{

  var done = 0;
  function execCommand1( e )
  {
    done = 1;
    console.log( 'execCommand1' );
  }

  var Commands =
  {
    'action1' : { e : execCommand1, h : 'Some action' },
    'action2' : '_assets/Action2.s',
    'action3' : '_assets/Action3.s',
  }

  var ca = _.CommandsAggregator
  ({
    basePath : __dirname,
    commands : Commands,
    commandPrefix : 'node ',
  }).form();

  var appArgs = Object.create( null );
  appArgs.subject = 'action1';
  appArgs.map = { action1 : true };
  appArgs.maps = [ appArgs.map ];
  appArgs.subjects = [ 'action1' ];
  done = 0;
  ca.appArgsPerform({ appArgs, allowingDotless : 1 });
  test.identical( done, 1 );

  var appArgs = Object.create( null );
  appArgs.subject = 'help';
  appArgs.map = { help : true };
  appArgs.maps = [ appArgs.map ];
  appArgs.subjects = [ 'help' ];
  ca.appArgsPerform({ appArgs, allowingDotless : 1 });
  test.identical( done, 1 );

  var appArgs = Object.create( null );
  appArgs.map = { action2 : true };
  appArgs.maps = [ appArgs.map ];
  appArgs.subject = 'action2';
  appArgs.subjects = [ 'action2' ];

  return ca.appArgsPerform({ appArgs, allowingDotless : 1 })
  .finally( function( err, arg )
  {
    test.true( !err );
    test.true( !!arg );
    var appArgs = Object.create( null );
    appArgs.map = { '.action3' : true };
    appArgs.maps = [ appArgs.map ];
    appArgs.subject = '.action3';
    appArgs.subjects = [ '.action3' ];
    return ca.appArgsPerform({ appArgs });
  })

  return result;
}

//

function perform( test )
{

  function commandWith( e )
  {

    test.description = 'integrity of the first event';
    test.identical( e.command, '.with path to dir .list all' );
    test.identical( e.commandName, '.with' );
    test.identical( e.commandArgument, 'path to dir .list all' );
    test.true( e.ca === ca );
    test.true( _.objectIs( e.subjectDescriptor ) );
    test.identical( e.subjectDescriptor.wholePhrase, 'with' );

    test.description = 'second command';
    let isolated = ca.commandIsolateSecondFromArgument( e.commandArgument );
    test.identical( isolated.commandArgument, 'path to dir' );
    test.identical( isolated.secondCommand, '.list all' );
    test.identical( isolated.secondCommandName, '.list' );
    test.identical( isolated.secondCommandArgument, 'all' );

    done = 1;

    e.ca.commandPerform
    ({
      command : isolated.secondCommand,
      propertiesMap : e.propertiesMap,
    });

  }

  function commandList( e )
  {
    let ca = e.ca;

    test.description = 'integrity of the second event';
    test.identical( e.command, '.list all' );
    test.identical( e.commandName, '.list' );
    test.identical( e.commandArgument, 'all' );
    test.true( e.ca === ca );
    test.true( _.objectIs( e.subjectDescriptor ) );
    test.identical( e.subjectDescriptor.wholePhrase, 'list' );

    done = 2;
  }

  var Commands =
  {
    'with' : { e : commandWith, h : 'With' },
    'list' : { e : commandList, h : 'List' },
  }

  var ca = _.CommandsAggregator
  ({
    commands : Commands,
  }).form();

  /* */

  test.case = 'appArgsPerform';
  var appArgs = Object.create( null );
  appArgs.subject = '.with path to dir .list all';
  done = 0;
  ca.appArgsPerform({ appArgs });
  test.identical( done, 2 );

  /* */

  test.case = 'commandsPerform with empty propertiesMaps';
  done = 0;
  ca.commandsPerform
  ({
    commands : '.with path to dir .list all',
    propertiesMaps : {},
  });
  test.identical( done, 2 );

  /* */

  test.case = 'commandsPerform without propertiesMaps';
  done = 0;
  ca.commandsPerform
  ({
    commands : '.with path to dir .list all',
  });
  test.identical( done, 2 );

  /* */

  test.case = 'commandsPerform with string';
  done = 0;
  ca.commandsPerform( '.with path to dir .list all' );
  test.identical( done, 2 );

  /* */

  test.case = 'commandPerform with empty properties map';
  var done = 0;
  ca.commandPerform
  ({
    command : '.with path to dir .list all',
    propertiesMap : Object.create( null ),
  });
  test.identical( done, 2 );

  /* */

  test.case = 'commandPerform without peroperties map';
  var done = 0;
  ca.commandPerform
  ({
    command : '.with path to dir .list all',
  });
  test.identical( done, 2 );

  /* */

  test.case = 'commandPerform with string';
  var done = 0;
  ca.commandPerform( '.with path to dir .list all' );
  test.identical( done, 2 );

  /* */

  test.case = 'commandPerformParsed';
  var done = 0;
  ca.commandPerformParsed
  ({
    command : '.with path to dir .list all',
    commandName : '.with',
    commandArgument : 'path to dir .list all',
  });
  test.identical( done, 2 );

}

//

function commandIsolateSecondFromArgument( test )
{

  var Commands =
  {
  }

  var ca = _.CommandsAggregator
  ({
    commands : Commands,
  }).form();

  test.case = 'with dot';
  var expected =
  {
    'commandArgument' : '',
    'secondCommandName' : '.module',
    'secondCommandArgument' : '.shell git status',
    'secondCommand' : '.module .shell git status',
  }
  var got = ca.commandIsolateSecondFromArgument( '.module .shell git status' );
  test.identical( got, expected );

  test.case = 'no second';
  var expected =
  {
    'commandArgument' : 'module git status',
    'secondCommandArgument' : '',
  };
  var got = ca.commandIsolateSecondFromArgument( 'module git status' );
  test.identical( got, expected );

  test.case = 'quoted doted commandArgument';
  var expected =
  {
    'commandArgument' : '".module" git status',
    'secondCommandArgument' : '',
  };
  var got = ca.commandIsolateSecondFromArgument( '".module" git status' );
  test.identical( got, expected );

  test.case = '"single with space/" .resources.list';
  var expected =
  {
    'commandArgument' : 'single with space/',
    'secondCommandName' : '.resources.list',
    'secondCommandArgument' : '',
    'secondCommand' : '.resources.list ',
  }
  var got = ca.commandIsolateSecondFromArgument( '"single with space/" .resources.list' );
  test.identical( got, expected );

  test.case = 'some/path/Full.stxt .';
  var expected =
  {
    'commandArgument' : 'some/path/Full.stxt .',
    'secondCommandArgument' : '',
  }
  var got = ca.commandIsolateSecondFromArgument( 'some/path/Full.stxt .' );
  test.identical( got, expected );

  test.case = 'some/path/Full.stxt ./';
  var expected =
  {
    'commandArgument' : 'some/path/Full.stxt ./',
    'secondCommandArgument' : '',
  }
  var got = ca.commandIsolateSecondFromArgument( 'some/path/Full.stxt ./' );
  test.identical( got, expected );

}

//

function help( test )
{
  let execCommand = () => {};
  let commandHelp = ( e ) => e.ca._commandHelp( e );

  var Commands =
  {
    'help' : { e : commandHelp, h : 'Get help.' },
    'action' : { e : execCommand, h : 'action' },
    'action first' : { e : execCommand, h : 'action first' },
  }

  let logger2 = new _.LoggerToString();
  let logger1 = new _.Logger({ outputs : [ _global_.logger, logger2 ], outputRaw : 1 });

  var ca = _.CommandsAggregator
  ({
    commands : Commands,
    logger : logger1,
  }).form();

  test.case = 'trivial help'
  logger2.outputData = '';
  ca.commandPerform({ command : '.help' });
  var expected =
  `
.help - Get help.
.action - action
.action.first - action first
`
  test.equivalent( logger2.outputData, expected );

  test.case = 'exact dotless'
  logger2.outputData = '';
  ca.commandPerform({ command : '.help action' });
  var expected = '  .action - action';
  test.identical( logger2.outputData, expected );

  test.case = 'exact with dot'
  logger2.outputData = '';
  ca.commandPerform({ command : '.help action' });
  var expected = '  .action - action';
  test.identical( logger2.outputData, expected );

  test.case = 'exact, two words, dotless'
  logger2.outputData = '';
  ca.commandPerform({ command : '.help action first' });
  var expected = '  .action.first - action first';
  test.identical( logger2.outputData, expected );

  test.case = 'exact, two words, with dot'
  logger2.outputData = '';
  ca.commandPerform({ command : '.help .action.first' });
  var expected = '  .action.first - action first';
  test.identical( logger2.outputData, expected );

  test.case = 'part of phrase, dotless'
  logger2.outputData = '';
  ca.commandPerform({ command : '.help first' });
  var expected = '  .action.first - action first\n  No command first';
  test.identical( logger2.outputData, expected );

  test.case = 'part of phrase, with dot'
  logger2.outputData = '';
  ca.commandPerform({ command : '.help .first' });
  var expected = '  .action.first - action first\n  No command .first';
  test.identical( logger2.outputData, expected );

}

//

function helpWithLongHint( test )
{
  /* init */

  let execCommand = () => {};
  let commandHelp = ( e ) => e.ca._commandHelp( e );

  var commands =
  {
    'help' :
    {
      e : commandHelp,
      h : 'Get help.',
      lh : 'Get common help and help for separate command.',
    },
    'action' :
    {
      e : execCommand,
      h : 'action',
      lh : 'Use command action to execute some action.'
    },
    'action first' :
    {
      e : execCommand,
      h : 'action first',
      lh : 'Define actions which will be executed first.'
    },
  };

  let loggerToString = new _.LoggerToString();
  let logger = new _.Logger({ outputs : [ _global_.logger, loggerToString ], outputRaw : 1 });

  var ca = _.CommandsAggregator
  ({
    commands,
    logger,
  }).form();

  /* */

  test.case = 'without subject'
  loggerToString.outputData = '';
  ca.commandPerform({ command : '.help' });
  var expected =
`
.help - Get help.
.action - action
.action.first - action first
`;
  test.equivalent( loggerToString.outputData, expected );

  test.case = 'dotless single word subject - single possible method';
  loggerToString.outputData = '';
  ca.commandPerform({ command : '.help action' });
  var expected = '  .action - Use command action to execute some action.';
  test.identical( loggerToString.outputData, expected );

  test.case = 'subject - two words, dotless'
  loggerToString.outputData = '';
  ca.commandPerform({ command : '.help action first' });
  var expected = '  .action.first - Define actions which will be executed first.';
  test.identical( loggerToString.outputData, expected );

  test.case = 'exact, two words, with dot'
  loggerToString.outputData = '';
  ca.commandPerform({ command : '.help .action.first' });
  var expected = '  .action.first - Define actions which will be executed first.';
  test.identical( loggerToString.outputData, expected );

  test.case = 'part of phrase, dotless'
  loggerToString.outputData = '';
  ca.commandPerform({ command : '.help first' });
  var expected = '  .action.first - Define actions which will be executed first.\n  No command first';
  test.identical( loggerToString.outputData, expected );

  test.case = 'part of phrase, with dot'
  loggerToString.outputData = '';
  ca.commandPerform({ command : '.help .first' });
  var expected = '  .action.first - Define actions which will be executed first.\n  No command .first';
  test.identical( loggerToString.outputData, expected );
}

//

function programPerform( test )
{
  let done = [];
  let command1 = ( e ) => { done.push( e ); };
  let command2 = ( e ) => { done.push( e ); };
  let logger2 = new _.LoggerToString();
  let logger1 = new _.Logger({ outputs : [ _global_.logger, logger2 ] });

  /* - */

  test.case = 'commandsImplicitDelimiting : 0, without ;';

  clean();

  var commands =
  {
    'command1' : { e : command1 },
    'command2' : { e : command2 },
  };

  var ca = _.CommandsAggregator
  ({
    commands,
    logger : logger1,
    commandsImplicitDelimiting : 0,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : '.command1 arg1 arg2 .command2 arg3' });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 arg1 arg2 .command2 arg3',
      'commandName' : '.command1',
      'commandArgument' : 'arg1 arg2 .command2 arg3',
      'subject' : 'arg1 arg2 .command2 arg3',
      'propertiesMap' : {},
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'commandsImplicitDelimiting : 0, with ;';

  clean();

  var commands =
  {
    'command1' : { e : command1 },
    'command2' : { e : command2 },
  };

  var ca = _.CommandsAggregator
  ({
    commands,
    logger : logger1,
    commandsImplicitDelimiting : 0,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : '.command1 arg1 arg2 ; .command2 arg3' });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 arg1 arg2',
      'commandName' : '.command1',
      'commandArgument' : 'arg1 arg2',
      'subject' : 'arg1 arg2',
      'propertiesMap' : {}
    },
    {
      'command' : '.command2 arg3',
      'commandName' : '.command2',
      'commandArgument' : 'arg3',
      'subject' : 'arg3',
      'propertiesMap' : {}
    }
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'commandsImplicitDelimiting : 1';

  clean();

  var commands =
  {
    'command1' : { e : command1 },
    'command2' : { e : command2 },
  };

  var ca = _.CommandsAggregator
  ({
    commands,
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : '.command1 arg1 arg2 .command2 arg3' });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 arg1 arg2',
      'commandName' : '.command1',
      'commandArgument' : 'arg1 arg2',
      'subject' : 'arg1 arg2',
      'propertiesMap' : {}
    },
    {
      'command' : '.command2 arg3',
      'commandName' : '.command2',
      'commandArgument' : 'arg3',
      'subject' : 'arg3',
      'propertiesMap' : {}
    }
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'commandsImplicitDelimiting : 1, with "';

  clean();

  var commands =
  {
    'command1' : { e : command1 },
    'command2' : { e : command2 },
  };

  var ca = _.CommandsAggregator
  ({
    commands,
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : '.command1 arg1 "arg2 .command2 arg3" .command2 "arg4 arg5" arg6' });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 arg1 "arg2 .command2 arg3"',
      'commandName' : '.command1',
      'commandArgument' : 'arg1 "arg2 .command2 arg3"',
      'subject' : 'arg1 "arg2 .command2 arg3"',
      'propertiesMap' : {}
    },
    {
      'command' : '.command2 "arg4 arg5" arg6',
      'commandName' : '.command2',
      'commandArgument' : '"arg4 arg5" arg6',
      'subject' : '"arg4 arg5" arg6',
      'propertiesMap' : {}
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'commandsImplicitDelimiting : 1, with " and ;';

  clean();

  var commands =
  {
    'command1' : { e : command1 },
    'command2' : { e : command2 },
  };

  var ca = _.CommandsAggregator
  ({
    commands,
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : '.command1 arg1 "arg2 .command2 arg3" .command2 "arg4 ; arg5" arg6 ; .command1 key:val' });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 arg1 "arg2 .command2 arg3"',
      'commandName' : '.command1',
      'commandArgument' : 'arg1 "arg2 .command2 arg3"',
      'subject' : 'arg1 "arg2 .command2 arg3"',
      'propertiesMap' : {}
    },
    {
      'command' : '.command2 "arg4 ; arg5" arg6',
      'commandName' : '.command2',
      'commandArgument' : '"arg4 ; arg5" arg6',
      'subject' : '"arg4 ; arg5" arg6',
      'propertiesMap' : {}
    },
    {
      'command' : '.command1 key:val',
      'commandName' : '.command1',
      'commandArgument' : 'key:val',
      'subject' : '',
      'propertiesMap' : { 'key' : 'val' }
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'commandsImplicitDelimiting : 1, trivial triplet';

  clean();

  var commands =
  {
    'command1' : { e : command1 },
    'command2' : { e : command2 },
  };

  var ca = _.CommandsAggregator
  ({
    commands,
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : '.command1 .command2 .command1' });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1',
      'commandName' : '.command1',
      'commandArgument' : '',
      'subject' : '',
      'propertiesMap' : {}
    },
    {
      'command' : '.command2',
      'commandName' : '.command2',
      'commandArgument' : '',
      'subject' : '',
      'propertiesMap' : {}
    },
    {
      'command' : '.command1',
      'commandName' : '.command1',
      'commandArgument' : '',
      'subject' : '',
      'propertiesMap' : {}
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'complex without subject';

  clean();

  var commands =
  {
    'command1' : { e : command1 },
    'command2' : { e : command2 },
  };

  var ca = _.CommandsAggregator
  ({
    commands,
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : '.command1 filePath:before/** ins:line sub:abc .command2 .command1' });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 filePath:before/** ins:line sub:abc',
      'commandName' : '.command1',
      'commandArgument' : 'filePath:before/** ins:line sub:abc',
      'subject' : '',
      'propertiesMap' : { 'filePath' : 'before/**', 'ins' : 'line', 'sub' : 'abc' }
    },
    {
      'command' : '.command2',
      'commandName' : '.command2',
      'commandArgument' : '',
      'subject' : '',
      'propertiesMap' : {}
    },
    {
      'command' : '.command1',
      'commandName' : '.command1',
      'commandArgument' : '',
      'subject' : '',
      'propertiesMap' : {}
    }
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'complex with subject';

  clean();

  var commands =
  {
    'command1' : { e : command1 },
    'command2' : { e : command2 },
  };

  var ca = _.CommandsAggregator
  ({
    commands,
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : '.command1  some subject  filePath:before/** ins:line sub:abc .command2 .command1' });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 some subject  filePath:before/** ins:line sub:abc', /* qqq : does not look right! */
      'commandName' : '.command1',
      'commandArgument' : 'some subject  filePath:before/** ins:line sub:abc',
      'subject' : 'some subject ',
      'propertiesMap' : { 'filePath' : 'before/**', 'ins' : 'line', 'sub' : 'abc' }
    },
    {
      'command' : '.command2',
      'commandName' : '.command2',
      'commandArgument' : '',
      'subject' : '',
      'propertiesMap' : {}
    },
    {
      'command' : '.command1',
      'commandName' : '.command1',
      'commandArgument' : '',
      'subject' : '',
      'propertiesMap' : {}
    }
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'several values';

  clean();

  var commands =
  {
    'command1' : { e : command1 },
    'command2' : { e : command2 },
  };

  var ca = _.CommandsAggregator
  ({
    commands,
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : '.command1 a:1 b:2 a:3 a:x .command2 a:4 a:a' });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 a:1 b:2 a:3 a:x',
      'commandName' : '.command1',
      'commandArgument' : 'a:1 b:2 a:3 a:x',
      'subject' : '',
      'propertiesMap' :
      {
        'a' : [ 1, 3, 'x' ],
        'b' : 2,
      }
    },
    {
      'command' : '.command2 a:4 a:a',
      'commandName' : '.command2',
      'commandArgument' : 'a:4 a:a',
      'subject' : '',
      'propertiesMap' :
      {
        'a' : [ 4, 'a' ],
      }
    }
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'quoted complex';

  clean();

  var commands =
  {
    'command1' : { e : command1 },
    'command2' : { e : command2 },
  };

  var ca = _.CommandsAggregator
  ({
    commands,
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : `.command1 "path/key 1":val1 "path/key 2":val2 "path/key3":'val3'` });

  commandsClean();

  var exp =
  [
    {
      'command' : `.command1 "path/key 1":val1 "path/key 2":val2 "path/key3":'val3'`,
      'commandName' : '.command1',
      'commandArgument' : `"path/key 1":val1 "path/key 2":val2 "path/key3":'val3'`,
      'subject' : '',
      'propertiesMap' : { 'path/key 2' : 'val2', 'path/key 1' : 'val1', 'path/key3' : 'val3' }
    }
  ];
  test.identical( done, exp ); /* xxx qqq : should work after fix of strRequestParse */
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* - */

  if( !Config.debug )
  return;

  test.case = 'notcommand prefix';

  clean();

  var commands =
  {
    'command1' : { e : command1 },
    'command2' : { e : command2 },
  };

  var ca = _.CommandsAggregator
  ({
    commands,
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
    changingExitCode : 0,
  }).form();

  test.shouldThrowErrorOfAnyKind
  (
    () => ca.programPerform({ program : 'notcommand .command1' }),
    ( err ) => test.identical( _.strCount( err.message, 'Illformed command' ), 1 ),
  );

  /* - */

  function commandsClean()
  {
    done.forEach( ( command ) =>
    {
      delete command.ca;
      delete command.subjectDescriptor;
    });
  }

  function clean()
  {
    logger2.outputData = '';
    done = [];
  }

}

//

function programPerformOptionSeveralValues( test )
{
  let done = [];
  let command1 = ( e ) => { done.push( e ); };
  let command2 = ( e ) => { done.push( e ); };
  let logger2 = new _.LoggerToString();
  let logger1 = new _.Logger({ outputs : [ _global_.logger, logger2 ] });

  /* - */

  test.case = 'severalValues - 1, commandsImplicitDelimiting - 0';

  clean();

  var ca = _.CommandsAggregator
  ({
    commands : { 'command1' : { e : command1 } },
    logger : logger1,
    commandsImplicitDelimiting : 0,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : '.command1 arg1 v:1 r:1 v:2' });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 arg1 v:1 r:1 v:2',
      'commandName' : '.command1',
      'commandArgument' : 'arg1 v:1 r:1 v:2',
      'subject' : 'arg1',
      'propertiesMap' : { 'v' : [ 1, 2 ], 'r' : 1 },
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'severalValues : 0, commandsImplicitDelimiting - 0';

  clean();

  var ca = _.CommandsAggregator
  ({
    commands : { 'command1' : { e : command1 } },
    logger : logger1,
    commandsImplicitDelimiting : 0,
    propertiesMapParsing : 1,
    severalValues : 0,
  }).form();

  ca.programPerform({ program : '.command1 arg1 v:1 r:1 v:2', severalValues : 0 });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 arg1 v:1 r:1 v:2',
      'commandName' : '.command1',
      'commandArgument' : 'arg1 v:1 r:1 v:2',
      'subject' : 'arg1',
      'propertiesMap' : { 'v' : 2, 'r' : 1 },
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'severalValues - 1, commandsImplicitDelimiting - 1';

  clean();

  var ca = _.CommandsAggregator
  ({
    commands : { 'command1' : { e : command1 } },
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
  }).form();

  ca.programPerform({ program : '.command1 arg1 v:1 r:1 v:2' });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 arg1 v:1 r:1 v:2',
      'commandName' : '.command1',
      'commandArgument' : 'arg1 v:1 r:1 v:2',
      'subject' : 'arg1',
      'propertiesMap' : { 'v' : [ 1, 2 ], 'r' : 1 },
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'severalValues : 0, commandsImplicitDelimiting - 1';

  clean();

  var ca = _.CommandsAggregator
  ({
    commands : { 'command1' : { e : command1 } },
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
    severalValues : 0,
  }).form();

  ca.programPerform({ program : '.command1 arg1 v:1 r:1 v:2', severalValues : 0 });

  commandsClean();

  var exp =
  [
    {
      'command' : '.command1 arg1 v:1 r:1 v:2',
      'commandName' : '.command1',
      'commandArgument' : 'arg1 v:1 r:1 v:2',
      'subject' : 'arg1',
      'propertiesMap' : { 'v' : 2, 'r' : 1 },
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* - */

  function commandsClean()
  {
    done.forEach( ( command ) =>
    {
      delete command.ca;
      delete command.subjectDescriptor;
    });
  }

  function clean()
  {
    logger2.outputData = '';
    done = [];
  }

}

//

function programPerformOptionSubjectWinPathMaybe( test )
{
  let done = [];
  let command1 = ( e ) => { done.push( e ); };
  let command2 = ( e ) => { done.push( e ); };
  let logger2 = new _.LoggerToString();
  let logger1 = new _.Logger({ outputs : [ _global_.logger, logger2 ] });

  /* - */

  test.case = 'severalValues - 1, commandsImplicitDelimiting - 0';

  clean();

  var ca = _.CommandsAggregator
  ({
    commands : { 'command1' : { e : command1 } },
    logger : logger1,
    commandsImplicitDelimiting : 0,
    propertiesMapParsing : 1,
  }).form();

  var subject = `${ _.path.nativize( _.path.current() ) }`;
  ca.programPerform({ program : `.command1 ${ subject } v:1 r:1 v:2`, subjectWinPathsMaybe : 1 });

  commandsClean();

  var exp =
  [
    {
      'command' : `.command1 ${ subject } v:1 r:1 v:2`,
      'commandName' : '.command1',
      'commandArgument' : `${ subject } v:1 r:1 v:2`,
      'subject' : `${ subject }`,
      'propertiesMap' : { 'v' : [ 1, 2 ], 'r' : 1 },
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'severalValues : 0, commandsImplicitDelimiting - 0';

  clean();

  var ca = _.CommandsAggregator
  ({
    commands : { 'command1' : { e : command1 } },
    logger : logger1,
    commandsImplicitDelimiting : 0,
    propertiesMapParsing : 1,
  }).form();

  var subject = `${ _.path.nativize( _.path.current() ) }`;
  ca.programPerform({ program : `.command1 ${ subject } v:1 r:1 v:2`, severalValues : 0, subjectWinPathsMaybe : 1 });

  commandsClean();

  var exp =
  [
    {
      'command' : `.command1 ${ subject } v:1 r:1 v:2`,
      'commandName' : '.command1',
      'commandArgument' : `${ subject } v:1 r:1 v:2`,
      'subject' : `${ subject }`,
      'propertiesMap' : { 'v' : 2, 'r' : 1 },
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'severalValues - 1, commandsImplicitDelimiting - 1';

  clean();

  var ca = _.CommandsAggregator
  ({
    commands : { 'command1' : { e : command1 } },
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
  }).form();

  var subject = `${ _.path.nativize( _.path.current() ) }`;
  ca.programPerform({ program : `.command1 ${ subject } v:1 r:1 v:2`, subjectWinPathsMaybe : 1 });

  commandsClean();

  var exp =
  [
    {
      'command' : `.command1 ${ subject } v:1 r:1 v:2`,
      'commandName' : '.command1',
      'commandArgument' : `${ subject } v:1 r:1 v:2`,
      'subject' : `${ subject }`,
      'propertiesMap' : { 'v' : [ 1, 2 ], 'r' : 1 },
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* */

  test.case = 'severalValues : 0, commandsImplicitDelimiting - 1';

  clean();

  var ca = _.CommandsAggregator
  ({
    commands : { 'command1' : { e : command1 } },
    logger : logger1,
    commandsImplicitDelimiting : 1,
    propertiesMapParsing : 1,
    severalValues : 0,
  }).form();

  var subject = `${ _.path.nativize( _.path.current() ) }`;
  ca.programPerform({ program : `.command1 ${ subject } v:1 r:1 v:2`, severalValues : 0, subjectWinPathsMaybe : 1 });

  commandsClean();

  var exp =
  [
    {
      'command' : `.command1 ${ subject } v:1 r:1 v:2`,
      'commandName' : '.command1',
      'commandArgument' : `${ subject } v:1 r:1 v:2`,
      'subject' : `${ subject }`,
      'propertiesMap' : { 'v' : 2, 'r' : 1 },
    },
  ];
  test.identical( done, exp );
  var exp = '';
  test.identical( logger2.outputData, exp );

  /* - */

  function commandsClean()
  {
    done.forEach( ( command ) =>
    {
      delete command.ca;
      delete command.subjectDescriptor;
    });
  }

  function clean()
  {
    logger2.outputData = '';
    done = [];
  }

}

//

function commandPropertiesAliases( test )
{
  let descriptor = null;

  //

  function command( e )
  {
    descriptor = e;
  }
  command.commandPropertiesAliases =
  {
    verbosity : [ 'v' ],
    routine : [ 'r' ]
  }
  command.commandProperties =
  {
    verbosity : 'verbosity',
    routine : 'routine',
  }

  //

  function commandAliasesArrayEmpty( e )
  {
    descriptor = e;
  }
  commandAliasesArrayEmpty.commandPropertiesAliases =
  {
    verbosity : []
  }
  commandAliasesArrayEmpty.commandProperties =
  {
    verbosity : 'verbosity'
  }

  //

  function commandAliasDuplication( e )
  {
    descriptor = e;
  }
  commandAliasDuplication.commandPropertiesAliases =
  {
    verbosity : [ 'v', 'v' ]
  }
  commandAliasDuplication.commandProperties =
  {
    verbosity : 'verbosity'
  }

  //

  function commandNoAliases( e )
  {
    descriptor = e;
  }
  commandNoAliases.commandProperties =
  {
    verbosity : 'verbosity'
  }

  //

  function commandSeveralAliasesToSameProperty( e )
  {
    descriptor = e;
  }
  commandSeveralAliasesToSameProperty.commandPropertiesAliases =
  {
    verbosity : [ 'v', 'v1' ]
  }
  commandSeveralAliasesToSameProperty.commandProperties =
  {
    verbosity : 'verbosity'
  }

  //

  let Commands =
  {
    'command' : { e : command, h : 'Test command' },
    'command.aliases.array.empty' : { e : commandAliasesArrayEmpty, h : 'Test command' },
    'command.alias.duplication' : { e : commandAliasDuplication, h : 'Test command' },
    'command.no.aliases' : { e : commandNoAliases, h : 'Test command' },
    'command.several.aliases.to.same.property' : { e : commandSeveralAliasesToSameProperty, h : 'Test command' },
  }

  let ca = _.CommandsAggregator
  ({
    commands : Commands,
    propertiesMapParsing : 1,
  }).form();

  /* */

  test.case = 'trivial';
  var appArgs = Object.create( null );
  appArgs.subject = '.command v:1 r:abc';
  ca.appArgsPerform({ appArgs });
  var expected = { verbosity : 1, routine : 'abc' }
  test.identical( descriptor.propertiesMap, expected );

  /* */

  test.case = 'alias and property together';
  var appArgs = Object.create( null );
  appArgs.subject = '.command verbosity:0 v:1 r:abc routine:xyz';
  ca.appArgsPerform({ appArgs });
  var expected = { verbosity : 1, routine : 'abc' }
  test.identical( descriptor.propertiesMap, expected );

  /* */

  test.case = 'no aliases';
  var appArgs = Object.create( null );
  appArgs.subject = '.command.no.aliases v:1 verbosity:1';
  ca.appArgsPerform({ appArgs });
  var expected = { verbosity : 1, v : 1 }
  test.identical( descriptor.propertiesMap, expected );

  /* */

  test.case = 'several aliases to same property';
  var appArgs = Object.create( null );
  appArgs.subject = '.command.several.aliases.to.same.property v:0 v1:1';
  ca.appArgsPerform({ appArgs });
  var expected = { verbosity : 1 }
  test.identical( descriptor.propertiesMap, expected );

  /* */

  if( !Config.debug )
  return;

  test.case = 'aliases array is empty';
  var appArgs = Object.create( null );
  appArgs.subject = '.command.aliases.array.empty v:1';
  test.shouldThrowErrorSync( () => ca.appArgsPerform({ appArgs }) )

  /* */

  test.case = 'alias duplication';
  var appArgs = Object.create( null );
  appArgs.subject = '.command.alias.duplication v:1';
  test.shouldThrowErrorSync( () => ca.appArgsPerform({ appArgs }) )
}

//

function helpForCommandWithAliases( test )
{

  let commandHelp = ( e ) => e.ca._commandHelp( e );

  function command( e )
  {
  }
  command.commandPropertiesAliases =
  {
    verbosity : [ 'v' ],
    routine : [ 'r' ]
  }
  command.commandProperties =
  {
    verbosity : 'verbosity',
    routine : 'routine',
  }

  function commandEmptyAliasesArray( e )
  {
  }
  commandEmptyAliasesArray.commandPropertiesAliases =
  {
    verbosity : [],
  }
  commandEmptyAliasesArray.commandProperties =
  {
    verbosity : 'verbosity',
    routine : 'routine',
  }

  function commandAliasDuplicated( e )
  {
  }
  commandAliasDuplicated.commandPropertiesAliases =
  {
    verbosity : [ 'v' ],
    routine : [ 'v' ]
  }
  commandAliasDuplicated.commandProperties =
  {
    verbosity : 'verbosity',
    routine : 'routine',
  }

  //

  let Commands =
  {
    'help' : { e : commandHelp, h : 'Get help.' },
    'command' : { e : command, h : 'Test command' },
    'command.aliases.array.empty' : { e : commandEmptyAliasesArray, h : 'Test command' },
    'command.alias.duplicated' : { e : commandAliasDuplicated, h : 'Test command' },
  }

  let logger2 = new _.LoggerToString();
  let logger1 = new _.Logger({ outputs : [ _global_.logger, logger2 ], outputRaw : 1 });

  let ca = _.CommandsAggregator
  ({
    commands : Commands,
    logger : logger1,
  }).form();

  /* */

  test.case = 'trivial'
  logger2.outputData = '';
  ca.commandPerform({ command : '.help command' });
  var expected =
  `.command - Test command
  v : verbosity
  verbosity : verbosity
  r : routine
  routine : routine`
  test.equivalent( logger2.outputData, expected );

  /* */

  if( !Config.debug )
  return;

  test.shouldThrowErrorSync( () => ca.commandPerform({ command : '.help command.aliases.array.empty' }) )
  test.shouldThrowErrorSync( () => ca.commandPerform({ command : '.help command.alias.duplicated' }) )
}

// --
// declare
// --

const Proto =
{

  name : 'Tools.mid.CommandsAggregator',
  silencing : 1,

  tests :
  {

    trivial,
    perform,
    commandIsolateSecondFromArgument,
    help,
    helpWithLongHint,
    programPerform,
    programPerformOptionSeveralValues,
    programPerformOptionSubjectWinPathMaybe,
    commandPropertiesAliases,
    helpForCommandWithAliases

  }

}

const Self = wTestSuite( Proto );
if( typeof module !== 'undefined' && !module.parent )
wTester.test( Self.name );

})();
