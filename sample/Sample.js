
let _ = require( 'wcommandsaggregator' );

/**/

function executable1( e )
{
  console.log( 'executable1' );
}

var Commands =
{
  'action1' : { e : executable1, h : 'Some action' },
  'action2' : 'Action2.s',
}

var ca = _.CommandsAggregator
({
  basePath : __dirname,
  commands : Commands,
  commandPrefix : 'node ',
}).form();

ca.execThis();
