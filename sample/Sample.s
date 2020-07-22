
let _ = require( 'wTools' );
require( 'wcommandsaggregator' );

/**/

function executable1( e )
{
  console.log( 'executable1' );
}

var Commands =
{
  'action first' : { e : executable1, h : 'Some action' },
  'action second' : 'Action2.s',
}

var ca = _.CommandsAggregator
({
  basePath : __dirname,
  commands : Commands,
  commandPrefix : 'node ',
}).form();

/* run first command */

var appArgs = Object.create( null );
appArgs.subject = '.action.first';
appArgs.map = { 'action first' : true };
appArgs.maps = [ appArgs.map ];
appArgs.subjects = [ '.action.first' ];
done = 0;
ca.appArgsPerform({ appArgs : appArgs, allowingDotless : 0 });
/* log : executable1 */

/* run second command */

var appArgs = Object.create( null );
appArgs.subject = '.action.second';
done = 0;
ca.appArgsPerform({ appArgs : appArgs, allowingDotless : 0 });
/* log :
 > node /.../wCommandsAggregator/sample/Action2.s .action.second
Action2
 */


