( function _CommandsAggregator_s_()
{

'use strict';

/**
 * Class aggregating several applications into single CLI. It can aggregate external binary applications as well as JS functions. Use it to expose CLI.
  @module Tools/mid/CommandsAggregator
*/

if( typeof module !== 'undefined' )
{
  let _ = require( '../../../../node_modules/Tools' );

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

const _ = _global_.wTools;
const Parent = null;
const Self = wCommandsAggregator;
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

  // debugger;
  _.workpiece.initFields( self );
  // debugger;
  // console.log( self.commandImplicitDelimeter );

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
  let appArgs = _.process.input();
  debugger;
  return self.programPerform({ program : appArgs.original });
  // return self.appArgsPerform({ appArgs });
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
  _.map.assertHasOnly( appArgs, appArgsNormalize.defaults );

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

// //
//
// /**
//  * @summary Reads provided application arguments and performs specified commands.
//  * @description Parses application arguments if they were not provided through options.
//  * @param {Object} o Options map.
//  * @param {Object} o.appArgs Parsed arguments.
//  * @param {Boolean} [o.printingEcho=1] Print command before execution.
//  * @param {Boolean} [o.allowingDotless=0] Allows to provide command without dot at the beginning.
//  * @function appArgsPerform
//  * @class wCommandsAggregator
//  * @namespace wTools
//  * @module Tools/mid/CommandsAggregator
//  */
//
// function appArgsPerform( o )
// {
//   let self = this;
//
//   _.assert( _.instanceIs( self ) );
//   _.assert( !!self.formed );
//   _.assert( arguments.length === 1 );
//   _.routineOptions( appArgsPerform, o );
//
//   if( o.appArgs === null )
//   o.appArgs = _.process.input();
//   o.appArgs = self.appArgsNormalize( o.appArgs );
//
//   _.assert( _.arrayIs( o.appArgs.subjects ) );
//   _.assert( _.arrayIs( o.appArgs.maps ) );
//
//   if( !o.allowingDotless )
//   if( !_.strBegins( o.appArgs.subject, '.' ) || _.strBegins( o.appArgs.subject, './' ) || _.strBegins( o.appArgs.subject, '.\\' ) )
//   {
//     self.onSyntaxError({ command : o.appArgs.subject });
//     return null;
//   }
//
//   if( o.printingEcho )
//   {
//     self.logger.rbegin({ verbosity : -1 });
//     self.logger.log( 'Command', self.logger.colorFormat( _.strQuote( o.appArgs.subjects.join( ' ; ' ) ), 'code' ) );
//     self.logger.rend({ verbosity : -1 });
//   }
//
//   /* */
//
//   return self.commandsPerform
//   ({
//     commands : o.appArgs.subjects,
//     propertiesMaps : o.appArgs.maps,
//   });
//
// }
//
// appArgsPerform.defaults =
// {
//   printingEcho : 1,
//   allowingDotless : 0,
//   appArgs : null,
// }

//

function programPerform( o )
{
  let self = this;
  let parsedCommands;
  let con = new _.Consequence().take( null );

  if( !_.mapIs( o ) )
  o = { program : arguments[ 0 ] };

  _.routineOptions( programPerform, o );
  _.assert( _.strIs( o.program ) );
  _.assert( !!self.formed );
  _.assert( arguments.length === 1 );

  o.program = o.program.trim();

  if( !o.allowingDotless )
  if( !_.strBegins( o.program, '.' ) || _.strBegins( o.program, './' ) || _.strBegins( o.program, '.\\' ) )
  {
    self.onSyntaxError({ command : o.program });
    return null;
  }

  if( o.printingEcho )
  {
    self.logger.rbegin({ verbosity : -1 });
    self.logger.log( 'Command', self.logger.colorFormat( _.strQuote( o.program ), 'code' ) );
    self.logger.rend({ verbosity : -1 });
  }

  {
    let o2 = _.mapOnly_( null, o, commandsParse.defaults );
    o2.commands = o.program;
    o2.propertiesMapParsing = 1;
    parsedCommands = self.commandsParse( o2 );
  }

  if( o.withParsed )
  {
    for( let c = 0 ; c < parsedCommands.length ; c++ )
    {
      let parsedCommand = parsedCommands[ c ];
      parsedCommand.parsedCommands = parsedCommands;
      con.then( () => self.commandPerformParsed( parsedCommand ) );
    }
  }
  else
  {
    for( let c = 0 ; c < parsedCommands.length ; c++ )
    {
      let parsedCommand = parsedCommands[ c ];
      con.then( () => self.commandPerformParsed( parsedCommand ) );
    }
  }

  return con;
}

programPerform.defaults =
{
  program : null,
  commandsImplicitDelimiting : null,
  commandsExplicitDelimiting : null,
  printingEcho : 1,
  withParsed : 0,
  severalValues : 1,
  subjectWinPathsMaybe : 0,
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
      let result = _.strSplit
      ({
        src : command,
        delimeter : self.commandImplicitDelimeter,
        // onDelimeter : ( del ) =>
        // {
        //   return [ del ];
        // }
      });

      result[ 0 ] = result[ 0 ].trim();

      if( result[ 0 ].length )
      {
      }
      else
      {
        result.splice( 0, 1 );
      }

      for( let i = 0 ; i < result.length-1 ; i += 1 )
      {
        result[ i ] = ( result[ i ].trim() + ' ' + result[ i+1 ].trim() ).trim();
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
    let o2 =
    {
      command,
      propertiesMap,
      propertiesMapParsing : o.propertiesMapParsing,
      severalValues : o.severalValues,
      subjectWinPathsMaybe : o.subjectWinPathsMaybe,
    };
    parsedCommands.push ( self.commandParse( o2 ) );
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
  severalValues : 1,
  subjectWinPathsMaybe : 0,
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
  if( o.severalValues === null )
  o.severalValues = self.severalValues;

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

    let request = _.strRequestParse
    ({
      src : commandArgument,
      commandsDelimeter : false,
      severalValues : o.severalValues,
      subjectWinPathsMaybe : o.subjectWinPathsMaybe,
    });

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
  severalValues : 1,
  subjectWinPathsMaybe : 0,
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

  o.commands = _.arrayFlatten( null, _.arrayAs( o.commands ) );

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
      command,
      propertiesMap : o.propertiesMaps[ c ],
    }));
  }

  return con.syncMaybe();
}

commandsPerform.defaults =
{
  commands : null,
  propertiesMaps : null,
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

  let parsedCommand = self.commandParse( o );
  let result = self.commandPerformParsed( parsedCommand );
  return result;
}

commandPerform.defaults =
{
  command : null,
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

  if( executable.commandPropertiesAliases )
  {
    let usedAliases = Object.create( null );
    _.assert( _.objectIs( executable.commandPropertiesAliases ) );
    for( let propName in executable.commandPropertiesAliases )
    {
      let aliases = _.arrayAs( executable.commandPropertiesAliases[ propName ] );
      _.assert( aliases.length >= 1 );
      aliases.forEach( ( alias ) =>
      {
        _.assert( !usedAliases[ alias ], `Alias ${alias} of property ${propName} is already in use.`)
        if( o.propertiesMap[ alias ] === undefined )
        return;
        o.propertiesMap[ propName ] = o.propertiesMap[ alias ];
        delete o.propertiesMap[ alias ];
        usedAliases[ alias ] = 1;
      })
    }
  }

  if( _.routineIs( executable ) )
  {
    let o2 =
    {
      command : o.command,
      commandName : o.commandName,
      commandArgument : o.commandArgument,
      subject : o.subject,
      propertiesMap : o.propertiesMap,
      ca : self,
      subjectDescriptor,
    };
    if( o.parsedCommands )
    o2.parsedCommands = o.parsedCommands;
    result = executable( o2 );
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
  parsedCommands : null,
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

  let splits = _.strIsolateLeftOrAll( command, ca.commandImplicitDelimeter );
  [ result.commandArgument, result.secondCommandName, result.secondCommandArgument  ] = splits;

  if( result.secondCommandName === undefined )
  delete result.secondCommandName;

  result.commandArgument = _.strUnquote( result.commandArgument.trim() );
  if( result.secondCommandName )
  result.secondCommandName = result.secondCommandName.trim();
  if( result.secondCommandArgument )
  result.secondCommandArgument = result.secondCommandArgument.trim();

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

  let splits = _.strIsolateRightOrAll( command, ca.commandImplicitDelimeter );
  [ result.commandArgument, result.secondCommandName, result.secondCommandArgument  ] = splits;

  if( result.secondCommandName === undefined )
  delete result.secondCommandName;

  result.commandArgument = _.strUnquote( result.commandArgument.trim() );
  if( result.secondCommandName )
  result.secondCommandName = result.secondCommandName.trim();
  if( result.secondCommandArgument )
  result.secondCommandArgument = result.secondCommandArgument.trim();

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
    logger.log( e.ca.vocabulary.helpForSubjectAsString({ phrase : e.commandArgument, filter }) );
    logger.up();

    let subject = e.ca.vocabulary.subjectDescriptorFor({ phrase : e.commandArgument, exact : 1 });

    if( !subject )
    {
      logger.log( 'No command', e.commandArgument );
    }
    else
    {
      if( subject.phraseDescriptor.executable && subject.phraseDescriptor.executable.commandProperties )
      logger.log( helpForOptionsMake( subject ) );
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

  /* */

  function filter( e )
  {
    return e.phraseDescriptor.longHint || e.phraseDescriptor.hint || _.strCapitalize( e.phraseDescriptor.phrase + '.' );
  }

  /* */

  function helpForOptionsMake( subject )
  {
    let executable = subject.phraseDescriptor.executable;
    let properties = executable.commandProperties;

    let options = _.mapKeys( properties )
    let hints = _.mapVals( properties );

    if( executable.commandPropertiesAliases )
    {
      let usedAliases = Object.create( null );
      _.assert( _.objectIs( executable.commandPropertiesAliases ) );
      for( let propName in executable.commandPropertiesAliases )
      {
        let aliases = _.arrayAs( executable.commandPropertiesAliases[ propName ] );
        _.assert( aliases.length >= 1 );
        aliases.forEach( ( alias ) =>
        {
          _.assert( !usedAliases[ alias ], `Alias ${alias} of property ${propName} is already in use.`)
          let hint = executable.commandProperties[ propName ];
          let propIndex = options.indexOf( propName );
          options.splice( propIndex, 0, alias );
          hints.splice( propIndex, 0, hint );
          usedAliases[ alias ] = 1;
        })
      }
    }

    options = _.ct.format( options, 'path' );

    let help = _.strJoin( [ options, ' : ', hints ] );
    return _.entity.exportString( help, { levels : 2, wrap : 0, stringWrapper : '', multiline : 1 } );
  }
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
      logger : _.logger.relative( cui.logger, 1 ),
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
  if( self.changingExitCode )
  _.process.exitCode( -1 );

  self.logger.log( 'Ambiguity. Did you mean?' );
  self.logger.log( self.vocabulary.helpForSubjectAsString( o.commandName ) );
  self.logger.log( '' );

}

onAmbiguity.defaults = Object.create( programPerform.defaults );

//

function onUnknownCommandError( o )
{
  let self = this;

  /* qqq : cover the case. check appExitCode. test should be external ( launch process ) */
  if( self.changingExitCode )
  _.process.exitCode( -1 );

  let s = 'Unknown command ' + _.strQuote( o.commandName );
  if( self.vocabulary.descriptorMap[ 'help' ] )
  s += '\nTry ".help"';
  let err = _.errBrief( s );
  debugger;
  throw err;
}

onUnknownCommandError.defaults = Object.create( commandPerformParsed.defaults );

//

function onSyntaxError( o )
{
  let self = this;

  /* qqq : cover the case. check appExitCode. test should be external ( launch process ) */
  if( self.changingExitCode )
  _.process.exitCode( -1 );

  let err = _.errBrief( 'Illformed command', self.logger.colorFormat( _.strQuote( o.command ), 'code' ) );
  self.logger.error( err );
  self.onGetHelp();
  throw err;
}

onSyntaxError.defaults =
{
  command : null,
}

// onSyntaxError.defaults = Object.create( appArgsPerform.defaults );

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
  // let knownFields =
  // {
  //   hint : null,
  //   defaults : null,
  //   commandProperties : null,
  // }

  if( phrase )
  {
    _.assert( phrase.length === 2 );
    executable = phrase[ 1 ];
    phrase = phrase[ 0 ];
  }

  let hint = phrase;
  let longHint;

  if( _.objectIs( executable ) )
  {
    // _.map.assertHasOnly( executable, { e : null, h : null } ); /* Dmytro : without longHint */
    // hint = executable.h;
    // executable = executable.e;

    _.map.assertHasOnly( executable, { e : null, h : null, lh : null } );
    hint = executable.h;
    longHint = executable.lh;
    executable = executable.e;
  }

  result.phrase = phrase;
  result.hint = hint;
  result.longHint = longHint;

  if( _.routineIs( executable ) )
  {
    result.executable = executable;
    if( executable.hint )
    {
      _.assert( result.hint === undefined || result.hint === null || result.hint === hint );
      result.hint = executable.hint;
    }
    if( executable.longHint )
    {
      _.assert( result.longHint === undefined || result.longHint === null || result.longHint === longHint );
      result.longHint = executable.longHint;
    }
    _.map.assertHasOnly( executable, self.CommandRoutineFields, () => `Unknown field of command "${result.phrase}" :` );
    // executable.commandDescriptor = result;
    // if( executable.originalRoutine )
    // executable.originalRoutine.commandDescriptor = result;
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

let CommandRoutineFields =
{
  defaults : null,
  hint : null,
  longHint : null,
  commandSubjectHint : null,
  commandProperties : null,
  commandPropertiesAliases : null,
}

let Composes =
{
  basePath : null,
  commandPrefix : '',
  addingDelimeter : ' ', /* qqq xxx : make it accessor */ /* qqq xxx : make possilbe both ":.command.postfix" and "command postfix" in definition of commands */
  commandExplicitDelimeter : ';',
  commandImplicitDelimeter : _.define.own( /(\s|^)\.\w[\w\.]*[^ \\\/\*\?](\s|$)/ ),
  // commandImplicitDelimeter : _.define.own( /(\s|^)\.(?:(?:\w[^ ]+))/ ),
  // commandImplicitDelimeter : _.define.own( /(\s|^)\.(?:(?:\w[^ ]*)|$)/ ), /* yyy */
  commandsExplicitDelimiting : 1,
  commandsImplicitDelimiting : 0,
  propertiesMapParsing : 0,
  severalValues : 1,
  lookingDelimeter : _.define.own([ '.', ' ' ]), /* qqq xxx : make it accessor */
  supplementingByHelp : 1,
  changingExitCode : 1,
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
  CommandRoutineFields,
}

let Forbids =
{
  verbosity : 'verbosity',
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

let Extension =
{

  init,
  form,
  _formVocabulary,
  exec,

  appArgsNormalize,
  // appArgsPerform,

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

  CommandRoutineFields,
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
  extend : Extension,
});

_.Copyable.mixin( Self );
// _.Verbal.mixin( Self );

//

_[ Self.shortName ] = Self;
if( typeof module !== 'undefined' )
module[ 'exports' ] = Self;

})();
