( function _CommandsAggregator_test_s_() {

'use strict';

if( typeof module !== 'undefined' )
{

  if( typeof _global_ === 'undefined' || !_global_.wBase )
  {
    var toolsPath = '../../../dwtools/Base.s';
    var toolsExternal = 0;
    try
    {
      toolsPath = require.resolve( toolsPath );
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

  require( '../l7/CommandsAggregator.s' );

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
  appArgs.map = {};
  ca.proceedApplicationArguments({ appArgs : appArgs });
  test.identical( executed1,1 );

  var appArgs = Object.create( null );
  appArgs.subject = 'help';
  appArgs.map = {};
  ca.proceedApplicationArguments({ appArgs : appArgs });
  test.identical( executed1,1 );

  var appArgs = Object.create( null );
  appArgs.map = {};
  appArgs.subject = 'action2';

  return ca.proceedApplicationArguments({ appArgs : appArgs })
  .doThen( function( err, arg )
  {
    test.is( !err );
    test.is( !!arg );
    var appArgs = Object.create( null );
    appArgs.map = {};
    appArgs.subject = 'action3';
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
_.Tester.test( Self.name );

})();
