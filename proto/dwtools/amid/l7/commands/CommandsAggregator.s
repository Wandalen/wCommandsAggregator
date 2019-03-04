( function _CommandsAggregator_s_() {

'use strict';

/**
 * Class aggregating several applications into single CLI. It can aggregate external binary applications as well as JS functions. Use it to expose CLI.
  @module Tools/mid/CommandsAggregator
*/

/**
 * @file CommandsAggregator.s.
 */


if( typeof module !== 'undefined' )
{

  let _ = require( '../../../Tools.s' );

  _.include( 'wCopyable' );
  _.include( 'wVocabulary' );
  _.include( 'wPathFundamentals' );
  _.include( 'wExternalFundamentals' );
  _.include( 'wFiles' );
  _.include( 'wVerbal' );

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

  self.logger = new _.Logger({ output : _global_.logger });

  _.instanceInit( self );
  Object.preventExtensions( self )

  if( o )
  self.copy( o );

  // if( self.logger === null )
  // self.logger = new _.Logger({ output : _global_.logger });

}

//

function form()
{
  let self = this;

  _.assert( !self.formed );
  _.assert( _.objectIs( self.commands ) );
  _.assert( arguments.length === 0 );

  self.basePath = _.path.resolve( self.basePath );

  if( self.supplementingByHelp && !self.commands.help )
  {
    self.commands.help = { e : self._commandHelp.bind( self ), h : 'Get help' };
  }

  self._formVocabulary();

  self.vocabulary.onPhraseDescriptorMake = self._onPhraseDescriptorMake.bind( self ),

  self.commandsAdd( self.commands );

  self.formed = 1;
  return self;
}

//

function _formVocabulary()
{
  let self = this;
  _.assert( arguments.length === 0 );
  self.vocabulary = self.vocabulary || _.Vocabulary();
  self.vocabulary.addingDelimeter = self.addingDelimeter;
  self.vocabulary.lookingDelimeter = self.lookingDelimeter;
}

//

function exec()
{
  let self = this;
  let appArgs = _.appArgs();
  return self.appArgsPerform({ appArgs : appArgs });
}

//

function appArgsNormalize( appArgs )
{
  let self = this;

  _.mapSupplement( appArgs, appArgsNormalize.defaults );
  _.assertMapHasOnly( appArgs, appArgsNormalize.defaults );

  appArgs.map = appArgs.map || Object.create( null );

  if( !appArgs.subjects )
  appArgs.subjects = _.strIs( appArgs.subject ) ? [ appArgs.subject ] : [];

  if( !appArgs.maps )
  appArgs.maps = _.mapIs( appArgs.map ) ? [ appArgs.map ] : [];

  return appArgs;
}

appArgsNormalize.defaults =
{
  subject : null,
  subjects : null,
  map : null,
  maps : null,
  interpreterPath : null,
  mainPath : null,
  interpreterArgs : null,
  scriptArgs : null,
  scriptString : null,

  keyValDelimeter : null,
  subjectsDelimeter : null,

}

//

function appArgsPerform( o )
{
  let self = this;

  _.assert( _.instanceIs( self ) );
  _.assert( !!self.formed );
  _.assert( arguments.length === 1 );
  _.routineOptions( appArgsPerform, o );

  if( o.appArgs === null )
  o.appArgs = _.appArgs();
  o.appArgs = self.appArgsNormalize( o.appArgs );

  _.assert( _.arrayIs( o.appArgs.subjects ) );
  _.assert( _.arrayIs( o.appArgs.maps ) );

  /* */

  if( !o.allowingDotless )
  if( !_.strBegins( o.appArgs.subject, '.' ) || _.strBegins( o.appArgs.subject, './' ) || _.strBegins( o.appArgs.subject, '.\\' ) )
  {
    self.logger.error( 'Illformed request', self.logger.colorFormat( _.strQuote( o.appArgs.subject ), 'code' ) );
    self.onGetHelp();
    return;
  }

  if( o.printingEcho )
  {
    self.logger.rbegin({ verbosity : -1 });
    self.logger.log( 'Request', self.logger.colorFormat( _.strQuote( o.appArgs.subjects.join( ' ; ' ) ), 'code' ) );
    self.logger.rend({ verbosity : -1 });
  }

  /* */

  return self.commandsPerform
  ({
    commands : o.appArgs.subjects,
    propertiesMaps : o.appArgs.maps,
  });

}

appArgsPerform.defaults =
{
  printingEcho : 1,
  allowingDotless : 0,
  appArgs : null,
}

//

function commandsPerform( o )
{
  let self = this;
  let con = new _.Consequence().take( null );
  let commands = [];

  if( _.strIs( o ) || _.arrayIs( o ) )
  o = { commands : o };

  _.routineOptions( commandsPerform, o );
  _.assert( _.strIs( o.commands ) || _.arrayIs( o.commands ) );
  _.assert( !!self.formed );
  _.assert( arguments.length === 1 );

  o.commands = _.arrayFlatten( null, _.arrayAs( o.commands ) );

  if( o.propertiesMaps === null || o.propertiesMaps.length === 0 )
  {
    o.propertiesMaps = _.dup( Object.create( null ), o.commands.length );
  }
  else
  {
    o.propertiesMaps = _.arrayFlatten( null, _.arrayAs( o.propertiesMaps ) );
  }

  for( let c = 0 ; c < o.commands.length ; c++ )
  {
    let command = o.commands[ c ];
    _.arrayAppendArray( commands, _.strSplitNonPreserving( command, ';' ) );
  }

  o.commands = _.arrayFlatten( null, commands );

  _.assert( o.commands.length === o.propertiesMaps.length );
  _.assert( o.commands.length !== 0, 'not tested' );

  for( let c = 0 ; c < o.commands.length ; c++ )
  {
    let command = o.commands[ c ];
    _.assert( command.trim() === command );
    // let splits = _.strIsolateLeftOrAll( command, ' ' );
    // debugger;
    con.keep( () => self.commandPerform
    ({
      command : command,
      // command : splits[ 0 ],
      // subject : splits[ 2 ],
      propertiesMap : o.propertiesMaps[ c ],
    }));
  }

  // debugger;
  return con.toResourceMaybe();
}

commandsPerform.defaults =
{
  commands : null,
  propertiesMaps : null,
}

//

function commandPerform( o )
{
  let self = this;

  if( _.strIs( o ) || _.arrayIs( o ) )
  o = { command : o };

  _.routineOptions( commandPerform, o );
  _.assert( _.strIs( o.command ) );
  _.assert( !!self.formed );
  _.assert( arguments.length === 1 );

  let splits = _.strIsolateLeftOrAll( o.command, ' ' );
  let subject = splits[ 0 ];
  let argument = splits[ 2 ];

  // let secondCommand = null;
  // let secondSubject = null;
  // let secondArgument = null;
  //
  // debugger;
  // if( self.complexSyntax )
  // {
  //   let second = self.commandIsolateSecondFromArgument( argument );
  //   if( second )
  //   {
  //     argument = second.argument;
  //     secondCommand = second.secondCommand;
  //     secondSubject = second.secondSubject;
  //     secondArgument = second.secondArgument;
  //   }
  // }

  o.propertiesMap = o.propertiesMap || Object.create( null );

  /* */

  let result = self.commandPerformParsed
  ({
    command : o.command,
    subject : subject,
    argument : argument,
    // secondCommand : secondCommand,
    // secondSubject : secondSubject,
    // secondArgument : secondArgument,
    propertiesMap : o.propertiesMap,
  });

  return result;
}

commandPerform.defaults =
{
  command : null,
  propertiesMap : null,
}

//

function commandPerformParsed( o )
{
  let self = this;
  let result;

  _.routineOptions( commandPerformParsed, o );
  _.assert( _.strIs( o.command ) );
  _.assert( _.strIs( o.subject ) );
  _.assert( _.strIs( o.argument ) );
  _.assert( o.propertiesMap === null || _.objectIs( o.propertiesMap ) );
  _.assert( _.instanceIs( self ) );
  _.assert( !!self.formed );
  _.assert( arguments.length === 1 );

  o.propertiesMap = o.propertiesMap || Object.create( null );

  /* */

  let subjectDescriptors = self.vocabulary.subjectDescriptorFor( o.subject );
  let filteredSubjectDescriptors;

  /* */

  if( !subjectDescriptors.length )
  {
    let s = 'Unknown subject ' + _.strQuote( o.subject );
    if( self.vocabulary.descriptorMap[ 'help' ] )
    s += '\nTry ".help"';
    throw _.errBriefly( s );
  }
  else
  {
    filteredSubjectDescriptors = self.vocabulary.subjectsFilter( subjectDescriptors, { wholePhrase : o.subject } );
    if( filteredSubjectDescriptors.length !== 1 )
    {
      self.logger.log( 'Ambiguity' );
      self.logger.log( self.vocabulary.helpForSubjectAsString( o.subject ) );
      self.logger.log( '' );
    }
    if( filteredSubjectDescriptors.length !== 1 )
    return null;
  }

  /* */

  let subjectDescriptor = filteredSubjectDescriptors[ 0 ];
  let executable = subjectDescriptor.phraseDescriptor.executable;
  if( _.routineIs( executable ) )
  {
    // debugger;
    result = executable
    ({
      command : o.command,
      subject : o.subject,
      argument : o.argument,

      // secondCommand : o.secondCommand,
      // secondSubject : o.secondSubject,
      // secondArgument : o.secondArgument,

      propertiesMap : o.propertiesMap,
      ca : self,
      subjectDescriptor : subjectDescriptor,
    });
  }
  else
  {
    // _.assert( !o.secondCommand, 'not implemented' );
    executable = _.path.nativize( executable );
    let mapStr = _.strJoinMap({ src : o.propertiesMap });
    let execPath = self.commandPrefix + executable + ' ' + o.subject + ' ' + mapStr;
    let o2 = Object.create( null );
    o2.execPath = execPath;
    result = _.shell( o2 );
  }

  if( result === undefined )
  result = null;

  return result;
}

commandPerformParsed.defaults =
{

  command : null,
  subject : null,
  argument : null,

  // secondCommand : null,
  // secondSubject : null,
  // secondArgument : null,

  propertiesMap : null,

}

//

function commandsAdd( commands )
{
  let self = this;

  _.assert( !self.formed );
  _.assert( arguments.length === 1 );

  self._formVocabulary();

  self.vocabulary.phrasesAdd( commands );

  return self;
}

//

function commandIsolateSecondFromArgument( command )
{
  let ca = this;
  let result = Object.create( null );

  _.assert( arguments.length === 1 );
  _.assert( _.strIs( command ) );

  [ result.argument, result.secondSubject, result.secondArgument  ] = _.strIsolateRightOrAll( command, /\s+\.\w[^ ]*\s*/ );

  if( !result.secondSubject )
  return null;

  result.secondSubject = result.secondSubject.trim();
  result.secondCommand = result.secondSubject + ' ' + result.secondArgument;

  return result;
}

//

function commandIsolateSecondFromArgumentDeprecated( subject )
{
  let ca = this;
  let result = Object.create( null );

  _.assert( arguments.length === 1 );

  [ result.subject, result.del1, result.secondCommand  ] = _.strIsolateLeftOrAll( subject, ' ' );
  [ result.secondCommand, result.del2, result.secondSubject  ] = _.strIsolateLeftOrAll( result.secondCommand, ' ' );

  return result;
}

//

function _commandHelp( e )
{
  let self = this;
  let ca = e.ca;
  let logger = self.logger || ca.logger || _global_.logger;

  if( e.subject )
  {

    logger.log();
    logger.log( e.ca.vocabulary.helpForSubjectAsString( e.subject ) );
    logger.up();

    let subjects = e.ca.vocabulary.subjectDescriptorForWithClause({ phrase : e.subject });

    if( subjects.length === 0 )
    {
      logger.log( 'No command', e.subject );
    }
    else if( subjects.length === 1 )
    {
      let subject = subjects[ 0 ];
      if( subject.phraseDescriptor.executable && subject.phraseDescriptor.executable.commandProperties )
      {
        let properties = subject.phraseDescriptor.executable.commandProperties;
        logger.log( _.toStr( properties, { levels : 2, wrap : 0, multiline : 1 } ) );
      }
    }

    logger.down();
    logger.log();

  }
  else
  {

    logger.log();
    logger.log( e.ca.vocabulary.helpForSubjectAsString( '' ) );
    logger.log();

    //logger.log( 'Use ' + logger.colorFormat( '"ts .help"', 'code' ) + ' to get help' );

  }

  return self;
}

// function _commandHelp( e )
// {
//   let ca = e.ca;
//
//   _.assert( arguments.length === 1 ); xxx
//
//   ca.logger.log( 'Commands to use' );
//   ca.onPrintCommands();
//
// }

//

function onGetHelp()
{
  let self = this;

  _.assert( arguments.length === 0 );

  // self.logger.log( self.vocabulary.helpForSubjectAsString( subjects[ 0 ] ) );
  // self.logger.log( '' );

  if( self.vocabulary.subjectDescriptorFor( '.help' ).length )
  {
    self.commandPerform({ command : '.help' });
  }
  else
  {
    self._commandHelp({ ca : self });
  }

}

//

function onPrintCommands()
{
  let self = this;

  _.assert( arguments.length === 0 );

  self.logger.log();
  self.logger.log( self.vocabulary.helpForSubjectAsString( '' ) );
  self.logger.log();

}

//

function _onPhraseDescriptorMake( src )
{

  _.assert(  _.strIs( src ) || _.arrayIs( src ) );
  _.assert( arguments.length === 1 );

  let self = this;
  let result = Object.create( null );
  let phrase = src;
  let executable = null;

  if( phrase )
  {
    _.assert( phrase.length === 2 );
    executable = phrase[ 1 ];
    phrase = phrase[ 0 ];
  }

  let hint = phrase;

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
    result.executable = _.path.resolve( self.basePath, executable );
    _.sure( !!_.fileProvider.statResolvedRead( result.executable ), () => 'Application not found at ' + _.strQuote( result.executable ) );
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
  addingDelimeter : ' ', // xxx
  lookingDelimeter : _.define.own([ '.' ]), // xxx
  complexSyntax : 0,
  supplementingByHelp : 1,
}

let Aggregates =
{
  onGetHelp : onGetHelp,
  onPrintCommands : onPrintCommands,
}

let Associates =
{
  logger : null,
  commands : null,
  vocabulary : null,
}

let Restricts =
{
  formed : 0,
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

let Extend =
{

  init,
  form,
  _formVocabulary,
  exec,

  appArgsNormalize,
  appArgsPerform,

  commandsPerform,
  commandPerform,
  commandPerformParsed,

  commandsAdd,

  commandIsolateSecondFromArgument,
  commandIsolateSecondFromArgumentDeprecated,

  _commandHelp,

  onGetHelp,
  onPrintCommands,
  _onPhraseDescriptorMake,

  //

  Composes,
  Aggregates,
  Associates,
  Restricts,
  Medials,
  Statics,
  Forbids,
  Accessors,

}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Extend,
});

_.Copyable.mixin( Self );
_.Verbal.mixin( Self );

//

_[ Self.shortName ] = Self;
if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
