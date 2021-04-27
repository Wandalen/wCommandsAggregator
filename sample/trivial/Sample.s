
require( 'wcommandsaggregator' );
let _ = wTools;

/* */

function executable1( e )
{
  console.log( 'executable1' );
}

var Commands =
{
  'action' : { ro : executable1, h : 'Some action' },
};

var ca = _.CommandsAggregator
({
  basePath : __dirname,
  commands : Commands,
  commandPrefix : 'node ',
}).form();

/* run first command */

ca.programPerform( '.action' );
/* log : executable1 */

