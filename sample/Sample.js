
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

ca.exec();
