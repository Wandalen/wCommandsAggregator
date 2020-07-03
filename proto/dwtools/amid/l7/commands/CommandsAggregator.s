( function _CommandsAggregator_s_() {

'use strict';

/**
 * Class aggregating several applications into single CLI. It can aggregate external binary applications as well as JS functions. Use it to expose CLI.
  @module Tools/mid/CommandsAggregator
*/

if( typeof module !== 'undefined' )
{

  let _ = require( '../../../../dwtools/Tools.s' );

  _.include( 'wCopyable' );
  _.include( 'wVocabulary' );
  _.include( 'wPathBasic' );
  _.include( 'wProcess' );
  _.include( 'wFiles' );
  _.include( 'wVerbal' );

}

/**
 * @classdesc Class aggregating several applications into single CLI.
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
 */

//

let _ = _global_.wTools;
let Parent = null;
let Self = wCommandsAggregator;
function wCommandsAggregator()
{
  return _.workpiece.construct( Self, this, arguments );
}

Self.shortName = 'CommandsAggregator';

//

function init( o )
{
  let self = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  self.logger = new _.Logger({ output : _global_.logger });

  _.workpiece.initFields( self );
  Object.preventExtensions( self )

  if( o )
  self.copy( o );

}

//

function form()
{
  let self = this;

  _.assert( !self.formed );
  _.assert( _.objectIs( self.commands ) );
  _.assert( arguments.length === 0, 'Expects no arguments' );

  self.basePath = _.path.resolve( self.basePath );

  if( self.supplementingByHelp && !self.commands.help )
  {
    self.commands.help = { e : self._commandHelp.bind( self ), h : 'Get help' };
  }

  self.commandsAdd( self.commands );

  self.formed = 1;
  return self;
}

//

function _formVocabulary()
{
  let self = this;

  _.assert( arguments.length === 0, 'Expects no arguments' );
  _.assert( self.vocabulary === null );

  self.vocabulary = self.vocabulary || _.Vocabulary();
  self.vocabulary.addingDelimeter = self.addingDelimeter;
  self.vocabulary.lookingDelimeter = self.lookingDelimeter;
  self.vocabulary.onPhraseDescriptorMake = self._onPhraseDescriptorMake.bind( self );

}

//

/**
 * @summary Reads app arguments and performs specified commands.
 * @function exec
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
 */

function exec()
{
  let self = this;
  let appArgs = _.process.args();
  return self.appArgsPerform({ appArgs : appArgs });
}

//

/**
 * @summary Normalizes application arguments.
 * @description
 * Checks if arguments object doesn't have redundant fields.
 * Supplements object with missing fields.
 * @param {Object} appArgs Application arguments.
 * @function appArgsNormalize
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
 */

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
  original : null,
  subject : null,
  subjects : null,
  map : null,
  maps : null,
  interpreterPath : null,
  interpreterArgs : null,
  interpreterArgsStrings : null,
  scriptPath : null,
  scriptArgs : null,
  scriptArgsString : null,
  keyValDelimeter : null,
  commandsDelimeter : null,
  caching : null,
  parsingArrays : null,
}

//

/**
 * @summary Reads provided application arguments and performs specified commands.
 * @description Parses application arguments if they were not provided through options.
 * @param {Object} o Options map.
 * @param {Object} o.appArgs Parsed arguments.
 * @param {Boolean} [o.printingEcho=1] Print command before execution.
 * @param {Boolean} [o.allowingDotless=0] Allows to provide command without dot at the beginning.
 * @function appArgsPerform
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
 */

function appArgsPerform( o )
{
  let self = this;

  _.assert( _.instanceIs( self ) );
  _.assert( !!self.formed );
  _.assert( arguments.length === 1 );
  _.routineOptions( appArgsPerform, o );

  if( o.appArgs === null )
  o.appArgs = _.process.args();
  o.appArgs = self.appArgsNormalize( o.appArgs );

  _.assert( _.arrayIs( o.appArgs.subjects ) );
  _.assert( _.arrayIs( o.appArgs.maps ) );

  if( !o.allowingDotless )
  if( !_.strBegins( o.appArgs.subject, '.' ) || _.strBegins( o.appArgs.subject, './' ) || _.strBegins( o.appArgs.subject, '.\\' ) )
  {
    self.onSyntaxError( o );
    return null;
  }

  if( o.printingEcho )
  {
    self.logger.rbegin({ verbosity : -1 });
    self.logger.log( 'Command', self.logger.colorFormat( _.strQuote( o.appArgs.subjects.join( ' ; ' ) ), 'code' ) );
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

function programPerform( o )
{
  let self = this;
  let parsedCommands;
  let con = new _.Consequence().take( null );

  _.routineOptions( programPerform, o );
  _.assert( _.strIs( o.program ) );
  _.assert( !!self.formed );
  _.assert( arguments.length === 1 );

  {
    let o2 = _.mapOnly( o, commandsParse.defaults );
    o2.commands = o.program;
    parsedCommands = self.commandsParse( o2 );
  }

  for( let c = 0 ; c < parsedCommands.length ; c++ )
  {
    let parsedCommand = parsedCommands[ c ];
    con.then( () => self.commandPerformParsed( parsedCommand ) );
  }

  return con;
}

programPerform.defaults =
{
  program : null,
  commandsImplicitDelimiting : null,
  commandsExplicitDelimiting : null,
}

//

function commandsParse( o )
{
  let self = this;
  let commands = [];

  if( _.strIs( o ) || _.arrayIs( o ) )
  o = { commands : o };

  _.routineOptions( commandsParse, o );
  _.assert( _.strIs( o.commands ) || _.arrayIs( o.commands ) );
  _.assert( !!self.formed );
  _.assert( arguments.length === 1 );

  if( o.commandsImplicitDelimiting === null )
  o.commandsImplicitDelimiting = self.commandsImplicitDelimiting;

  if( o.commandsExplicitDelimiting === null )
  o.commandsExplicitDelimiting = self.commandsExplicitDelimiting;

  o.commands = _.arrayFlatten( null, _.arrayAs( o.commands ) );

  commands = o.commands;
  commands = _.filter_( null, commands, ( command ) =>
  {
    let result = _.strSplitNonPreserving( command, self.commandExplicitDelimeter );
    return _.unrollFrom( result );
  });

  if( o.commandsImplicitDelimiting )
  {

    commands = _.filter_( null, commands, ( command ) =>
    {
      let result = _.strSplit( command, self.commandImplicitDelimeter );

      for( let i = 1 ; i < result.length-1 ; i += 2 )
      {
        result[ i ] = result[ i ] + ' ' + result[ i+1 ];
        result.splice( i+1, 1 );
      }

      return _.unrollFrom( result );
    });

  }

  commands = _.arrayFlatten( null, commands );

  let parsedCommands = [];

  for( let c = 0 ; c < commands.length ; c++ )
  {
    let command = commands[ c ];
    let propertiesMap = o.propertiesMaps ? o.propertiesMaps[ c ] : null;
    parsedCommands.push( self.commandParse({ command : command, propertiesMap }) );
  }

  return parsedCommands
}

commandsParse.defaults =
{
  commands : null,
  commandsImplicitDelimiting : null,
  commandsExplicitDelimiting : null,
  propertiesMapParsing : null,
  propertiesMaps : null,
}

//

function commandParse( o )
{
  let self = this;

  if( _.strIs( o ) || _.arrayIs( o ) )
  o = { command : o };

  _.routineOptions( commandParse, o );
  _.assert( _.strIs( o.command ) );
  _.assert( !!self.formed );
  _.assert( arguments.length === 1 );

  if( o.propertiesMapParsing === null )
  o.propertiesMapParsing = self.propertiesMapParsing;

  let splits = _.strIsolateLeftOrAll( o.command, ' ' );
  let commandName = splits[ 0 ];
  let commandArgument = splits[ 2 ];

  o.propertiesMap = o.propertiesMap || Object.create( null );

  let parsed =
  {
    command : o.command,
    commandName,
    commandArgument,
    propertiesMap : o.propertiesMap,
  }

  if( o.propertiesMapParsing )
  {

    debugger;
    let request = _.strRequestParse
    ({
      src : commandArgument,
      commandsDelimeter : false,
    });

    debugger;
    parsed.propertiesMap = _.mapExtend( parsed.propertiesMap || null, request.map );
    parsed.subject = request.subject

  }

  return parsed;
}

commandParse.defaults =
{
  command : null,
  propertiesMap : null,
  propertiesMapParsing : null,
}

//

/**
 * @summary Perfroms requested command(s) one by one.
 * @description Multiple commands in one string should be separated by semicolon.
 * @param {Object} o Options map.
 * @param {Array|String} o.commands Command(s) to execute.
 * @param {Array} o.propertiesMaps Array of maps with options for commands.
 * @function commandsPerform
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
 */

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

  // if( o.commandsImplicitDelimiting === null )
  // o.commandsImplicitDelimiting = self.commandsImplicitDelimiting;

  o.commands = _.arrayFlatten( null, _.arrayAs( o.commands ) );

  // for( let c = 0 ; c < o.commands.length ; c++ )
  // {
  //   let command = o.commands[ c ];
  //   _.arrayAppendArray( commands, _.strSplitNonPreserving( command, self.commandExplicitDelimeter ) );
  // }

  // commands = o.commands;
  // commands = _.filter_( null, commands, ( command ) =>
  // {
  //   let result = _.strSplitNonPreserving( command, self.commandExplicitDelimeter );
  //   return _.unrollFrom( result );
  // });
  //
  // debugger;
  // if( o.commandsImplicitDelimiting )
  // {
  //
  //   commands = _.filter_( null, commands, ( command ) =>
  //   {
  //     let result = _.strSplit( command, self.commandImplicitDelimeter );
  //
  //     for( let i = 1 ; i < result.length-1 ; i += 2 )
  //     {
  //       result[ i ] = result[ i ] + ' ' + result[ i+1 ];
  //       result.splice( i+1, 1 );
  //     }
  //
  //     return _.unrollFrom( result );
  //   });
  //
  // }
  //
  // o.commands = _.arrayFlatten( null, commands );

  if( o.propertiesMaps === null || o.propertiesMaps.length === 0 )
  {
    o.propertiesMaps = _.dup( Object.create( null ), o.commands.length );
  }
  else
  {
    o.propertiesMaps = _.arrayFlatten( null, _.arrayAs( o.propertiesMaps ) );
  }

  _.assert( o.commands.length === o.propertiesMaps.length );
  _.assert( o.commands.length !== 0, 'not tested' );

  for( let c = 0 ; c < o.commands.length ; c++ )
  {
    let command = o.commands[ c ];
    _.assert( command.trim() === command );
    con.then( () => self.commandPerform
    ({
      command : command,
      propertiesMap : o.propertiesMaps[ c ],
    }));
  }

  return con.syncMaybe();
}

commandsPerform.defaults =
{
  commands : null,
  propertiesMaps : null,
  // commandsImplicitDelimiting : null,
  // commandsExplicitDelimiting : null,
}

//

/**
 * @summary Perfroms requested command.
 * @param {Object} o Options map.
 * @param {String} o.command Command to execute.
 * @param {Array} o.propertiesMap Options for provided command.
 * @function commandPerform
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
 */

function commandPerform( o )
{
  let self = this;

  if( _.strIs( o ) || _.arrayIs( o ) )
  o = { command : o };

  _.routineOptions( commandPerform, o );
  _.assert( _.strIs( o.command ) );
  _.assert( !!self.formed );
  _.assert( arguments.length === 1 );

  // let splits = _.strIsolateLeftOrAll( o.command, ' ' );
  // // let subject = splits[ 0 ]; /* yyy */
  // // let argument = splits[ 2 ];
  // let commandName = splits[ 0 ];
  // let commandArgument = splits[ 2 ];
  //
  // o.propertiesMap = o.propertiesMap || Object.create( null );

  let parsedCommand = self.commandParse( o );

  let result = self.commandPerformParsed( parsedCommand );

  // ({
  //   command : o.command,
  //   commandName,
  //   commandArgument,
  //   propertiesMap : o.propertiesMap,
  //   // prev : o.prev,
  // });

  return result;
}

commandPerform.defaults =
{
  command : null,
  // prev : null,
  propertiesMap : null,
}

//

/**
 * @descriptionNeeded
 * @param {Object} o Options map.
 * @param {String} o.command Command to execute.
 * @param {String} o.commandName
 * @param {String} o.commandArgument
 * @param {Array} o.propertiesMap Options for provided command.
 * @function commandPerformParsed
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
 */

function commandPerformParsed( o )
{
  let self = this;
  let result;

  _.routineOptions( commandPerformParsed, o );
  _.assert( _.strIs( o.command ) );
  _.assert( _.strIs( o.commandName ) );
  _.assert( _.strIs( o.commandArgument ) );
  _.assert( o.propertiesMap === null || _.objectIs( o.propertiesMap ) );
  _.assert( _.instanceIs( self ) );
  _.assert( !!self.formed );
  _.assert( arguments.length === 1 );

  o.propertiesMap = o.propertiesMap || Object.create( null );

  /* */

  let subjectDescriptors = self.vocabulary.subjectDescriptorFor( o.commandName );
  let filteredSubjectDescriptors;

  /* */

  if( !subjectDescriptors.length )
  {
    self.onUnknownCommandError( o );
    return null;
  }
  else
  {
    filteredSubjectDescriptors = self.vocabulary.subjectsFilter( subjectDescriptors, { wholePhrase : o.commandName } );
    if( filteredSubjectDescriptors.length !== 1 )
    {
      let e = _.mapExtend( null, o );
      e.filteredSubjectDescriptors = filteredSubjectDescriptors;
      self.onAmbiguity( e );
    }
    if( filteredSubjectDescriptors.length !== 1 )
    return null;
  }

  /* */

  let subjectDescriptor = filteredSubjectDescriptors[ 0 ];
  let executable = subjectDescriptor.phraseDescriptor.executable;
  if( _.routineIs( executable ) )
  {
    result = executable
    ({
      command : o.command,
      commandName : o.commandName,
      commandArgument : o.commandArgument,
      propertiesMap : o.propertiesMap,
      ca : self,
      subjectDescriptor : subjectDescriptor,
    });
  }
  else
  {
    executable = _.path.nativize( executable );
    let mapStr = _.strJoinMap({ src : o.propertiesMap });
    let execPath = self.commandPrefix + executable + ' ' + o.commandName + ' ' + o.commandArgument + ' ' + mapStr;
    let o2 = Object.create( null );
    o2.execPath = execPath;
    result = _.process.start( o2 );
  }

  if( result === undefined )
  result = null;

  return result;
}

commandPerformParsed.defaults =
{

  command : null,
  commandName : null,
  commandArgument : null,
  propertiesMap : null,
  subject : null,
  // prev : null,

}

//

/**
 * @summary Adds commands to the vocabulary.
 * @param {Array} commands Array with commands to add.
 * @function commandsAdds
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
*/

function commandsAdd( commands )
{
  let self = this;

  _.assert( !self.formed );
  _.assert( arguments.length === 1 );

  if( !self.vocabulary )
  self._formVocabulary();

  self.vocabulary.phrasesAdd( commands );

  return self;
}

//

/**
 * @summary Separates second command from provided string.
 * @param {String} command Commands string to parse.
 * @function commandIsolateSecondFromArgumentLeft
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
*/

function commandIsolateSecondFromArgumentLeft( command )
{
  let ca = this;
  let result = Object.create( null );

  _.assert( arguments.length === 1 );
  _.assert( _.strIs( command ) );

  [ result.commandArgument, result.secondCommandName, result.secondCommandArgument  ] = _.strIsolateLeftOrAll( command, ca.commandImplicitDelimeter );
  /* qqq : cover please
    dont forget about case : "some/path/Full.stxt ."
  */

  result.commandArgument = _.strUnquote( result.commandArgument.trim() );

  if( result.secondCommandName )
  {
    result.secondCommandName = result.secondCommandName.trim();
    result.secondCommand = result.secondCommandName + ' ' + result.secondCommandArgument;
  }

  return result;
}

//

function commandIsolateSecondFromArgumentRight( command )
{
  let ca = this;
  let result = Object.create( null );

  _.assert( arguments.length === 1 );
  _.assert( _.strIs( command ) );

  [ result.commandArgument, result.secondCommandName, result.secondCommandArgument  ] = _.strIsolateRightOrAll( command, ca.commandImplicitDelimeter );
  /* qqq : cover please
    dont forget about case : "some/path/Full.stxt ."
  */

  if( result.secondCommandName )
  {
    result.secondCommandName = _.strUnquote( result.secondCommandName.trim() );
    result.secondCommand = result.secondCommandName + ' ' + result.secondCommandArgument;
  }

  return result;
}

//

/*
  .help - Prints list of available commands with description
  .help commandName
    - Exact match - Prints description of command and properties.
    - Partial match - Prints list of commands that have provided commandName.
    - No match - Prints No command found.
*/

function _commandHelp( e )
{
  let self = this;
  let ca = e.ca;
  let logger = self.logger || ca.logger || _global_.logger;

  if( e.commandArgument )
  {
    logger.log();
    logger.log( e.ca.vocabulary.helpForSubjectAsString( e.commandArgument ) );
    logger.up();

    let subject = e.ca.vocabulary.subjectDescriptorFor({ phrase : e.commandArgument, exact : 1 });

    if( !subject )
    {
      logger.log( 'No command', e.commandArgument );
    }
    else
    {
      debugger;
      if( subject.phraseDescriptor.executable && subject.phraseDescriptor.executable.commandProperties )
      {
        let properties = subject.phraseDescriptor.executable.commandProperties;
        logger.log( _.toStr( properties, { levels : 2, wrap : 0, multiline : 1, wrap : 0, stringWrapper : '' } ) );
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

  }

  return self;
}

_commandHelp.hint = 'Get help.';

//

function _commandVersion_functor( fop )
{

  _.routineOptions( _commandVersion_functor, arguments );
  _.assert( _.strDefined( fop.packageJsonPath ) );
  _.assert( _.strDefined( fop.packageName ) );

  _commandVersion.hint = 'Get information about version.';
  return _commandVersion;

  function _commandVersion( e )
  {
    let cui = this;

    return _.npm.versionLog
    ({
      localPath : fop.localPath,
      remotePath : fop.remotePath,
    });
  }

}

_commandVersion_functor.defaults =
{
  localPath : null,
  remotePath : null,
}

//

function onAmbiguity( o )
{
  let self = this;
  /* qqq : cover the case. check appExitCode. test should be external ( launch process ) */
  _.process.exitCode( -1 );

  self.logger.log( 'Ambiguity. Did you mean?' );
  self.logger.log( self.vocabulary.helpForSubjectAsString( o.commandName ) );
  self.logger.log( '' );

}

onAmbiguity.defaults = Object.create( appArgsPerform.defaults );

//

function onUnknownCommandError( o )
{
  let self = this;
  /* qqq : cover the case. check appExitCode. test should be external ( launch process ) */
  _.process.exitCode( -1 );
  let s = 'Unknown command ' + _.strQuote( o.commandName );
  if( self.vocabulary.descriptorMap[ 'help' ] )
  s += '\nTry ".help"';
  throw _.errBrief( s );
}

onUnknownCommandError.defaults = Object.create( commandPerformParsed.defaults );

//

function onSyntaxError( o )
{
  let self = this;
  /* qqq : cover the case. check appExitCode. test should be external ( launch process ) */
  _.process.exitCode( -1 );
  self.logger.error( 'Illformed command', self.logger.colorFormat( _.strQuote( o.appArgs.subject ), 'code' ) );
  self.onGetHelp();
}

onSyntaxError.defaults = Object.create( appArgsPerform.defaults );

//

function onGetHelp()
{
  let self = this;

  _.assert( arguments.length === 0, 'Expects no arguments' );

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

  _.assert( arguments.length === 0, 'Expects no arguments' );

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
  let knownFields =
  {
    hint : null,
    defaults : null,
    commandProperties : null,
  }

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
    if( executable.hint )
    {
      _.assert( result.hint === undefined || result.hint === null || result.hint === hint );
      result.hint = executable.hint;
    }
    _.assertMapHasOnly( executable, knownFields, () => `Unknown field of command "${result.phrase}" :` );
  }
  else
  {
    _.assert( _.strIs( executable ) );
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
  addingDelimeter : ' ', /* qqq xxx : make it accessor */ /* qqq xxx : make possilbe both ":.command.postfix" and "command postfix" in definition of commands */
  commandExplicitDelimeter : ';',
  commandImplicitDelimeter : _.define.own( /\s+\.(?:(?:\w[^ ]*)|$)\s*/ ),
  propertiesMapParsing : 0,
  commandsExplicitDelimiting : 1,
  commandsImplicitDelimiting : 0,
  lookingDelimeter : _.define.own([ '.' ]), /* qqq xxx : make it accessor */
  supplementingByHelp : 1,
}

let Aggregates =
{
  onSyntaxError,
  onAmbiguity,
  onUnknownCommandError,
  onGetHelp,
  onPrintCommands,
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

  programPerform,

  commandsParse,
  commandParse,
  commandsPerform,
  commandPerform,
  commandPerformParsed,

  commandsAdd,

  commandIsolateSecondFromArgument : commandIsolateSecondFromArgumentLeft,
  commandIsolateSecondFromArgumentLeft,
  commandIsolateSecondFromArgumentRight,

  _commandHelp,
  _commandVersion_functor,

  onSyntaxError,
  onAmbiguity,
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
if( typeof module !== 'undefined' )
module[ 'exports' ] = Self;

})();
