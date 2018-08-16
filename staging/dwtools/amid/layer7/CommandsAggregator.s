( function _CommandsAggregator_s_() {

'use strict';

/**
  @module Tools/mid/CommandsAggregator - Class aggregating several applications into single CLI. It can aggregate external binary applications as well as JS functions. Use it to expose CLI.
*/

/**
 * @file CommandsAggregator.s.
 */

if( typeof module !== 'undefined' )
{

  if( typeof _global_ === 'undefined' || !_global_.wBase )
  {
    let toolsPath = '../../../dwtools/Base.s';
    let toolsExternal = 0;
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

  let _ = _global_.wTools;

  _.include( 'wCopyable' );
  _.include( 'wVocabulary' );

}

//

let _ = _global_.wTools;
let Parent = null;
let Self = function wCommandsAggregator()
{
  return _.instanceConstructor( Self, this, arguments );
}

Self.shortName = 'CommandsAggregator';

//

function init( o )
{
  let self = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  _.instanceInit( self );
  Object.preventExtensions( self )

  if( o )
  self.copy( o );

}

//

function form()
{
  let self = this;

  _.assert( !self._formed );
  _.assert( _.objectIs( self.commands ) );
  self._formed = 1;

  self.basePath = _.path.resolve( self.basePath );

  if( self.supplementingByHelp && !self.commands.help )
  {
    self.commands.help = { e : self._help.bind( self ), h : 'Get help' };
  }

  self.vocabulary = _.Vocabulary();
  self.vocabulary.onDescriptorMake = self._onPhraseDescriptorMake.bind( self ),
  self.vocabulary.phrasesAdd( self.commands );

  return self;
}

//

function execThis()
{
  let self = this;
  let appArgs = _.appArgs();
  return self.proceed( appArgs );
}

//

function proceed( appArgs )
{
  let self = this;
  let subjects = _.strIsolateBeginOrAll( appArgs.subject.trim(), ' ' );

  _.assert( _.instanceIs( self ) );
  _.assert( !!self._formed );

  let subjectDescriptor = self.vocabulary.subjectDescriptorFor
  ({
    subject : subjects[ 0 ],
    delimeter : [ '.' ],
    exact : 1,
  });

  if( !subjectDescriptor )
  throw _.errBriefly( 'Unknown subject ' + _.strQuote( appArgs.subject ) );

  let executable = subjectDescriptor.phraseDescriptor.executable;
  if( _.routineIs( executable ) )
  {
    return executable
    ({
      subject : subjects[ 1 ],
      map : appArgs.map,
      phrase : subjectDescriptor.phraseDescriptor.phrase,
    });
  }
  else
  {
    executable = _.path.nativize( executable );
    let mapStr = _.strJoinMap({ src : appArgs.map });
    let shellStr = self.commandPrefix + executable + ' ' + mapStr + ' ' + subjects[ 1 ];
    return _.shell( shellStr );
  }

}

//

function _help( e )
{
  let self = this;

  // let subject = self.vocabulary.subjectDescriptorFor( '' );
  // logger.log( subject );

  logger.log( ' Commands to use' );
  logger.log();
  logger.log( _.toStr( self.vocabulary.helpForSubject( '' ), { levels : 2, wrap : 0, stringWrapper : '', multiline : 1 } ) );

}

//

function _onPhraseDescriptorMake( src )
{

  _.assert( _.arrayIs( src ) && src.length === 2 );
  _.assert( arguments.length === 1 );

  let self = this;
  let phrase = src[ 0 ];
  let hint = phrase;
  let executable = src[ 1 ];
  let result = Object.create( null );

  if( _.objectIs( executable ) )
  {
    _.assertMapHasOnly( executable, { e : null, h : null } );
    hint = executable.h;
    executable = executable.e;
  }

  result.phrase = phrase;
  result.hint = hint;

  if( _.routineIs( executable ) )
  {
    result.executable = executable;
  }
  else
  {
    result.executable = _.path.join( self.basePath, executable );
    _.sure( !!_.fileProvider.fileStat( result.executable ), () => 'Application not found at ' + _.strQuote( result.executable ) );
  }

  return result;
}

// --
//
// --

let Composes =
{
  basePath : null,
  commandPrefix : '',
  supplementingByHelp : 1,
}

let Aggregates =
{
}

let Associates =
{
  commands : null,
  vocabulary : null,
}

let Restricts =
{
  _formed : 0,
}

let Statics =
{
}

let Forbids =
{
}

let Accessors =
{
}

let Medials =
{
}

// --
// prototype
// --

let Proto =
{

  init : init,
  form : form,
  execThis : execThis,
  proceed : proceed,

  _help : _help,
  _onPhraseDescriptorMake : _onPhraseDescriptorMake,

  //

  Composes : Composes,
  Aggregates : Aggregates,
  Associates : Associates,
  Restricts : Restricts,
  Medials : Medials,
  Statics : Statics,
  Forbids : Forbids,
  Accessors : Accessors,

}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Proto,
});

_.Copyable.mixin( Self );
// _.Verbal.mixin( Self );

//

_[ Self.shortName ] = Self;
if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
