( function _CommandsAggregator_test_s_() {

'use strict';

if( typeof module !== 'undefined' )
{
  if( typeof _global_ === 'undefined' || !_global_.wBase )
  {
    let toolsPath = '../../../../dwtools/Base.s';
    let toolsExternal = 0;
    try
    {
      require.resolve( toolsPath );
    }
    catch( err )
    {
      toolsExternal = 1;
      require( 'wTools' );
    }
    if( !toolsExternal )
    require( toolsPath );
  }

  var _ = _global_.wTools;

  _.include( 'wTesting' );

  require( '../l7/commands/CommandsAggregator.s' );

}

var _global = _global_;
var _ = _global_.wTools;

// --
//
// --

function trivial( test )
{

  var executed1 = 0;
  function executable1( e )
  {
    executed1 = 1;
    console.log( 'Executable1' );
  }

  var Commands =
  {
    'action1' : { e : executable1, h : 'Some action' },
    'action2' : 'Action2.s',
    'action3' : 'Action3.s',
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
  executed1 = 0;
  ca.proceedApplicationArguments({ appArgs : appArgs, allowingDotless : 1 });
  test.identical( executed1,1 );

  var appArgs = Object.create( null );
  appArgs.subject = 'help';
  appArgs.map = { help : true };
  appArgs.maps = [ appArgs.map ];
  appArgs.subjects = [ 'help' ];
  ca.proceedApplicationArguments({ appArgs : appArgs, allowingDotless : 1 });
  test.identical( executed1,1 );

  var appArgs = Object.create( null );
  appArgs.map = { action2 : true };
  appArgs.maps = [ appArgs.map ];
  appArgs.subject = 'action2';
  appArgs.subjects = [ 'action2' ];

  return ca.proceedApplicationArguments({ appArgs : appArgs, allowingDotless : 1 })
  .finally( function( err, arg )
  {
    test.is( !err );
    test.is( !!arg );
    var appArgs = Object.create( null );
    appArgs.map = { '.action3' : true };
    appArgs.maps = [ appArgs.map ];
    appArgs.subject = '.action3';
    appArgs.subjects = [ '.action3' ];
    return ca.proceedApplicationArguments({ appArgs : appArgs });
  })

  return result;
}

// --
//
// --

var Self =
{

  name : 'Tools/mid/CommandsAggregator',
  silencing : 1,

  tests :
  {
    trivial : trivial,
  }

}

Self = wTestSuite( Self );
if( typeof module !== 'undefined' && !module.parent )
wTester.test( Self.name );

})();
