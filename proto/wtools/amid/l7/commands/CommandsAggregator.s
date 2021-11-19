( function _CommandsAggregator_s_()
{

'use strict';

/**
 * The tool to make CLI ( commands user interface ). It is able to aggregate external binary applications, as well as functions, which are written in your language.
 * @module Tools/mid/CommandsAggregator
*/

if( typeof module !== 'undefined' )
{
  const _ = require( '../../../../node_modules/Tools' );

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

// --
// inter
// --

function init( o )
{
  let aggregator = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  aggregator.logger = _.logger.fromStrictly( o ? o.logger || 1 : 1 );

  _.workpiece.initFields( aggregator );
  Object.preventExtensions( aggregator )

  if( o )
  {
    aggregator.copy( o );
    // if( o.delimeter )
    // aggregator._.delimeter = o.delimeter;
  }

}

//

function form()
{
  let aggregator = this;

  _.assert( !aggregator.formed );
  _.assert( _.object.isBasic( aggregator.commands ) || _.longIs( aggregator.commands ) );
  _.assert( arguments.length === 0, 'Expects no arguments' );

  aggregator.basePath = _.path.resolve( aggregator.basePath );

  aggregator.commandsAdd( aggregator.commands );

  if( aggregator.withHelp && !aggregator.vocabulary.phraseMap[ 'help' ] )
  {
    let commandHelp = { ro : aggregator._commandHelp.bind( aggregator ), h : 'Get help' };
    aggregator.commandsAdd({ 'help' : commandHelp });
  }

  aggregator.commands = null;
  aggregator.formed = 1;
  return aggregator;
}

//

function _formVocabulary()
{
  let aggregator = this;

  _.assert( arguments.length === 0, 'Expects no arguments' );
  _.assert( aggregator.vocabulary === null );
  _.assert( !!aggregator.delimeter );

  aggregator.vocabulary = aggregator.vocabulary || new _.Vocabulary();
  aggregator.vocabulary.delimeter = aggregator.delimeter;
  aggregator.vocabulary.onPhraseDescriptorIs = aggregator.commandIs.bind( aggregator );
  aggregator.vocabulary.onPhraseDescriptorFrom = aggregator.commandFrom.bind( aggregator );
  aggregator.vocabulary.preform();

}

//

function aggregatorExtend_functor( routine )
{
  return function aggregatorExtend( o )
  {
    if( !o.dst )
    o.dst = this;

    _.routine.options( aggregatorExtend, o );
    _.assert( _.instanceIs( o.src ) );
    _.assert( _.instanceIs( o.dst ) );

    let extensionMap = Object.create( null );
    if( o.only )
    _.mapOnly_( extensionMap, o.src.vocabulary.phraseMap, o.only );
    else
    _.object.extend( extensionMap, o.src.vocabulary.phraseMap );

    if( o.but )
    _.mapBut_( extensionMap, extensionMap, o.but );

    routine( o.dst.vocabulary.phraseMap, extensionMap );
    for( let key in extensionMap )
    extensionMap[ key ] = [ extensionMap[ key ] ];
    routine( o.dst.vocabulary.wordMap, extensionMap );

    o.dst.vocabulary.descriptorSet = _.set.make( [] );
    for( let key in o.dst.vocabulary.phraseMap )
    o.dst.vocabulary.descriptorSet.add( o.dst.vocabulary.phraseMap[ key ] );

    return o.dst;
  }
}

//

const extend = aggregatorExtend_functor( _.object.extend.bind( _.object ) );
extend.defaults =
{
  src : null,
  dst : null,
  but : null,
  only : null,
};

//

const supplement = aggregatorExtend_functor( _.object.supplement.bind( _.object ) );
supplement.defaults = extend.defaults;

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
  let aggregator = this;
  let appArgs = _.process.input();
  return aggregator.programPerform({ program : appArgs.original });
  // return aggregator.appArgsPerform({ appArgs });
}

//

/* qqq : xxx : cover Exec */

function Exec( o )
{
  let aggregator = new Self( o );
  return aggregator.exec();
}

// --
// run
// --

function programPerform( o )
{
  let aggregator = this;
  let parsedCommands;
  let con = new _.Consequence().take( null );

  if( !_.mapIs( o ) )
  o = { program : arguments[ 0 ] };

  _.routine.options( programPerform, o );
  _.assert( _.strIs( o.program ) );
  _.assert( !!aggregator.formed, 'Commands aggregator is not formed' );
  _.assert( arguments.length === 1 );

  o.program = o.program.trim();

  /* xxx : investigate option::allowingDotless */
  if( !o.allowingDotless )
  if
  (
    !_.strBegins( o.program, aggregator.vocabulary.defaultDelimeter )
    || _.strBegins( o.program, `${aggregator.vocabulary.defaultDelimeter}/` )
    || _.strBegins( o.program, `${aggregator.vocabulary.defaultDelimeter}\\` )
  )
  {
    aggregator.onSyntaxError({ command : o.program });
    return null;
  }

  if( o.printingEcho )
  {
    aggregator.logger.rbegin({ verbosity : -1 });
    aggregator.logger.log( 'Command', _.ct.format( _.strQuote( o.program ), 'code' ) );
    aggregator.logger.rend({ verbosity : -1 });
  }

  {
    let o2 = _.mapOnly_( null, o, instructionsParse.defaults );
    o2.commands = o.program;
    o2.propertiesMapParsing = 1;
    parsedCommands = aggregator.instructionsParse( o2 );
  }

  for( let c = 0 ; c < parsedCommands.length ; c++ )
  {
    let parsedCommand = parsedCommands[ c ];
    if( o.withParsed )
    parsedCommand.parsedCommands = parsedCommands;
    parsedCommand.index = c;
    con.then( () => aggregator.instructionPerformParsedLooking( parsedCommand ) );
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
  severalValues : null,
  subjectWinPathsMaybe : 0, /* xxx : qqq : remove */
  // allowingDotless : 0, /* Dmytro : option does not used in the utilities */
}

//

/**
 * @summary Perfroms requested command(s) one by one.
 * @description Multiple commands in one string should be separated by semicolon.
 * @param {Object} o Options map.
 * @param {Array|String} o.commands Command(s) to execute.
 * @param {Array} o.propertiesMaps Array of maps with options for commands.
 * @function instructionsPerform
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
 */

function instructionsPerform( o )
{
  let aggregator = this;
  let con = new _.Consequence().take( null );
  let commands = [];

  if( _.strIs( o ) || _.arrayIs( o ) )
  o = { commands : o };

  _.routine.options( instructionsPerform, o );
  _.assert( _.strIs( o.commands ) || _.arrayIs( o.commands ) );
  _.assert( !!aggregator.formed );
  _.assert( arguments.length === 1 );

  o.commands = _.arrayFlatten( null, _.array.as( o.commands ) );

  if( o.propertiesMaps === null || o.propertiesMaps.length === 0 )
  {
    o.propertiesMaps = _.dup( Object.create( null ), o.commands.length );
  }
  else
  {
    o.propertiesMaps = _.arrayFlatten( null, _.array.as( o.propertiesMaps ) );
  }

  _.assert( o.commands.length === o.propertiesMaps.length );
  _.assert( o.commands.length !== 0, 'not tested' );

  for( let c = 0 ; c < o.commands.length ; c++ )
  {
    let command = o.commands[ c ];
    _.assert( command.trim() === command );
    con.then( () => aggregator.instructionPerform
    ({
      command,
      propertiesMap : o.propertiesMaps[ c ],
    }));
  }

  return con.syncMaybe();
}

instructionsPerform.defaults =
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
 * @function instructionPerform
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
 */

function instructionPerform( o )
{
  let aggregator = this;

  if( _.strIs( o ) || _.arrayIs( o ) )
  o = { command : o };

  _.routine.options( instructionPerform, o );
  _.assert( _.strIs( o.command ) );
  _.assert( !!aggregator.formed );
  _.assert( arguments.length === 1 );

  let parsedCommand = aggregator.instructionParse( o );
  let result = aggregator.instructionPerformParsedLooking( parsedCommand );
  return result;
}

instructionPerform.defaults =
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
 * @param {String} o.instructionArgument
 * @param {Array} o.propertiesMap Options for provided command.
 * @function instructionPerformParsedLooking
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
 */

function instructionPerformParsedLooking( o )
{
  let aggregator = this;

  _.routine.options( instructionPerformParsedLooking, o );
  _.assert( _.strIs( o.command ) );
  _.assert( _.strIs( o.commandName ) );
  _.assert( _.strIs( o.instructionArgument ) );
  _.assert( o.propertiesMap === null || _.object.isBasic( o.propertiesMap ) );
  _.assert( _.instanceIs( aggregator ) );
  _.assert( !!aggregator.formed );
  _.assert( arguments.length === 1 );

  o.propertiesMap = o.propertiesMap || Object.create( null );

  let command = aggregator.commandLook({ commandName : o.commandName });
  let o2 = _.props.extend( null, o );
  o2.phraseDescriptor = command;
  return aggregator.instructionPerformParsedFound( o2 );
}

instructionPerformParsedLooking.defaults =
{
  command : null,
  commandName : null,
  instructionArgument : null,
  propertiesMap : null,
  subject : null,
  parsedCommands : null,
  index : null,
}

//

function instructionPerformParsedFound( o )
{
  let aggregator = this;
  let result;

  _.routine.options( instructionPerformParsedFound, o );
  _.assert( _.strIs( o.command ) );
  _.assert( _.strIs( o.commandName ) );
  _.assert( _.strIs( o.instructionArgument ) );
  _.assert( o.propertiesMap === null || _.object.isBasic( o.propertiesMap ) );
  _.assert( _.instanceIs( aggregator ) );
  _.assert( !!aggregator.formed );
  _.assert( arguments.length === 1 );
  _.assert( aggregator.commandIs( o.phraseDescriptor ) );

  o.aggregator = o.aggregator || aggregator;
  o.propertiesMap = o.propertiesMap || Object.create( null );

  /* */

  let phraseDescriptor = o.phraseDescriptor;
  let routine = phraseDescriptor.routine;

  _.assert( _.routineIs( routine ) );

  if( phraseDescriptor.propertiesAliases )
  {
    let usedAliases = Object.create( null );
    _.assert( _.object.isBasic( phraseDescriptor.propertiesAliases ) );
    for( let propName in phraseDescriptor.propertiesAliases )
    {
      let aliases = _.array.as( phraseDescriptor.propertiesAliases[ propName ] );
      _.assert( aliases.length >= 1 );
      aliases.forEach( ( alias ) =>
      {
        _.assert( !usedAliases[ alias ], `Alias ${alias} of property ${propName} is already in use.` )
        if( o.propertiesMap[ alias ] === undefined )
        return;
        o.propertiesMap[ propName ] = o.propertiesMap[ alias ];
        delete o.propertiesMap[ alias ];
        usedAliases[ alias ] = 1;
      })
    }
  }

  if( _.routineIs( routine ) )
  {
    let o2 = o;
    if( o.parsedCommands )
    o2.parsedCommands = o.parsedCommands;
    result = routine( o2 );
  }
  else
  {
    /* xxx : generate routine from this */
    routine = _.path.nativize( routine );
    let mapStr = _.strJoinMap({ src : o.propertiesMap });
    let execPath = aggregator.commandPrefix + routine + ' ' + o.commandName + ' ' + o.instructionArgument + ' ' + mapStr;
    let o2 = Object.create( null );
    o2.execPath = execPath;
    result = _.process.start( o2 );
  }

  if( result === undefined )
  result = null;

  return result;
}

instructionPerformParsedFound.defaults =
{
  ... instructionPerformParsedLooking.defaults,
  phraseDescriptor : null,
}

// --
// parse
// --

function instructionsParse( o )
{
  let aggregator = this;
  let commands = [];

  if( _.strIs( o ) || _.arrayIs( o ) )
  o = { commands : o };

  _.routine.options( instructionsParse, o );
  _.assert( _.strIs( o.commands ) || _.arrayIs( o.commands ) );
  _.assert( !!aggregator.formed );
  _.assert( arguments.length === 1 );

  if( o.commandsImplicitDelimiting === null )
  o.commandsImplicitDelimiting = aggregator.commandsImplicitDelimiting;

  if( o.commandsExplicitDelimiting === null )
  o.commandsExplicitDelimiting = aggregator.commandsExplicitDelimiting;

  o.commands = _.arrayFlatten( null, _.array.as( o.commands ) );

  commands = o.commands;
  commands = _.filter_( null, commands, ( command ) =>
  {
    let result = _.strSplitNonPreserving( command, aggregator.commandExplicitDelimeter );
    return _.unroll.from( result );
  });

  if( o.commandsImplicitDelimiting )
  {

    commands = _.filter_( null, commands, ( command ) =>
    {
      let result = _.strSplit
      ({
        src : command,
        delimeter : aggregator.commandImplicitDelimeter,
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
        result[ i ] = ( result[ i ].trim() + ' ' + result[ i+1 ].trim() ).trim(); /* xxx : qqq : ? */
        result.splice( i+1, 1 );
      }

      return _.unroll.from( result );
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
    parsedCommands.push( aggregator.instructionParse( o2 ) );
  }

  return parsedCommands
}

instructionsParse.defaults =
{
  commands : null, /* xxx : rename to instructions */
  commandsImplicitDelimiting : null,
  commandsExplicitDelimiting : null,
  propertiesMapParsing : null,
  propertiesMaps : null,
  severalValues : null,
  subjectWinPathsMaybe : 0, /* xxx : qqq : what for? remove by callback isSubject? */
}

//

function instructionParse( o )
{
  let aggregator = this;

  if( _.strIs( o ) )
  o = { command : o };

  _.assert( arguments.length === 1 );
  _.routine.options( instructionParse, o );
  _.assert( _.strIs( o.command ) );
  _.assert( !!aggregator.formed );

  let quote = [ '"', '`', '\'' ];
  if( o.propertiesMapParsing === null )
  o.propertiesMapParsing = aggregator.propertiesMapParsing;
  if( o.severalValues === null )
  o.severalValues = aggregator.severalValues;
  if( _.boolLikeTrue( o.quoting ) )
  o.quoting = quote;
  if( o.unquoting === null )
  o.unquoting = o.quoting ? 1 : 0;

  /* */

  let splits = _.strIsolateLeftOrAll( o.command, ' ' );
  let commandName = splits[ 0 ];
  let instructionArgument = splits[ 2 ];

  o.propertiesMap = o.propertiesMap || Object.create( null );

  let parsed =
  {
    command : o.command,
    commandName,
    instructionArgument,
    propertiesMap : o.propertiesMap,
  };

  let request = Object.create( null );
  if( o.quoting )
  {
    let isolated = _.strIsolateLeftOrAll
    ({
      src : instructionArgument,
      delimeter : ' ',
      quote : _.arrayAppendArray( null, o.quoting ),
    });

    if( isolated[ 0 ] === instructionArgument )
    {
      if( !_.strHas( instructionArgument, ':' ) )
      request.subject = instructionArgument;

      if( o.unquoting )
      {
        let inside = _.strInsideOf_({ src : instructionArgument, begin : o.quoting, end : o.quoting });
        if( inside[ 1 ] !== undefined )
        request.subject = inside[ 1 ];
      }

      if( request.subject )
      return parsedExtend();
    }

    if( o.propertiesMapParsing && o.unquoting )
    instructionArgument = `'${ instructionArgument }'`;
  }
  else
  {
    if( o.unquoting )
    instructionArgument = unquoteInstructionArgument();
  }

  if( o.propertiesMapParsing )
  request = requestParse( instructionArgument );
  else
  request.subject = instructionArgument;

  return parsedExtend();

  /* */

  function requestParse( src )
  {
    return _.strRequestParse
    ({
      src,
      commandsDelimeter : false,
      severalValues : o.severalValues,
      subjectWinPathsMaybe : o.subjectWinPathsMaybe,
      quoting : o.quoting,
      unquoting : o.unquoting,
    });
  }

  /* */

  function parsedExtend()
  {
    if( request.map )
    parsed.propertiesMap = _.mapExtend( parsed.propertiesMap, request.map );
    if( request.subject !== undefined )
    parsed.subject = request.subject;
    return parsed;
  }

  /* */

  function unquoteInstructionArgument()
  {
    let args = [];
    let src = instructionArgument;
    let isolated;
    do
    {
      isolated = _.strIsolateLeftOrAll
      ({
        src,
        delimeter : ' ',
        quote,
      });
      src = isolated[ 2 ];
      args.push( _.strUnquote( isolated[ 0 ] ) )
    }
    while( isolated[ 2 ] )

    return args.join( ' ' );
  }
}

instructionParse.defaults =
{
  command : null,
  propertiesMap : null,
  propertiesMapParsing : null,
  severalValues : null,
  quoting : 1,
  unquoting : null,
  subjectWinPathsMaybe : 0,
}

// function instructionParse( o )
// {
//   let aggregator = this;
//
//   // if( _.strIs( o ) || _.arrayIs( o ) ) /* Dmytro : routine should non parse commands in array, assertion below approve it */
//   if( _.strIs( o ) )
//   o = { command : o };
//
//   _.assert( arguments.length === 1 );
//   _.routine.options( instructionParse, o );
//   _.assert( _.strIs( o.command ) );
//   _.assert( !!aggregator.formed );
//
//   if( o.propertiesMapParsing === null )
//   o.propertiesMapParsing = aggregator.propertiesMapParsing;
//   if( o.severalValues === null )
//   o.severalValues = aggregator.severalValues;
//
//   let splits = _.strIsolateLeftOrAll( o.command, ' ' );
//   let commandName = splits[ 0 ];
//   let instructionArgument = splits[ 2 ];
//
//   o.propertiesMap = o.propertiesMap || Object.create( null );
//
//   let parsed =
//   {
//     command : o.command,
//     commandName,
//     instructionArgument,
//     propertiesMap : o.propertiesMap,
//   };
//
//   if( o.propertiesMapParsing )
//   {
//     let request = _.strRequestParse
//     ({
//       src : instructionArgument,
//       commandsDelimeter : false,
//       severalValues : o.severalValues,
//       subjectWinPathsMaybe : o.subjectWinPathsMaybe,
//       unquoting : o.unquoting,
//     });
//
//     // parsed.propertiesMap = _.mapExtend( parsed.propertiesMap || null, request.map ); /* Dmytro : parsed.propertiesMap can have some value or be empty pure map, see line 560 */
//     parsed.propertiesMap = _.mapExtend( parsed.propertiesMap, request.map );
//     parsed.subject = request.subject
//   }
//
//   return parsed;
// }
//
// instructionParse.defaults =
// {
//   command : null,
//   propertiesMap : null,
//   propertiesMapParsing : null,
//   severalValues : null,
//   unquoting : 0,
//   subjectWinPathsMaybe : 0,
// };

//

/**
 * @summary Separates second command from provided string.
 * @param {String} command Commands string to parse.
 * @function instructionIsolateSecondFromArgumentLeft
 * @class wCommandsAggregator
 * @namespace wTools
 * @module Tools/mid/CommandsAggregator
*/

function instructionIsolateSecondFromArgumentLeft( instruction )
{
  let aggregator = this;
  let result = Object.create( null );

  _.assert( arguments.length === 1 );
  _.assert( _.strIs( instruction ) );

  let splits = _.strIsolateLeftOrAll( instruction, aggregator.commandImplicitDelimeter );
  [ result.instructionArgument, result.secondInstructionName, result.secondInstructionArgument ] = splits;

  if( result.secondInstructionName === undefined )
  delete result.secondInstructionName;

  result.instructionArgument = _.strUnquote( result.instructionArgument.trim() );
  if( result.secondInstructionName )
  result.secondInstructionName = result.secondInstructionName.trim();
  if( result.secondInstructionArgument )
  result.secondInstructionArgument = result.secondInstructionArgument.trim();

  if( result.secondInstructionName )
  {
    result.secondInstructionName = result.secondInstructionName.trim();
    result.secondInstruction = result.secondInstructionName + ' ' + result.secondInstructionArgument;
  }

  return result;
}

//

function instructionIsolateSecondFromArgumentRight( instruction )
{
  let aggregator = this;
  let result = Object.create( null );

  _.assert( arguments.length === 1 );
  _.assert( _.strIs( instruction ) );

  let splits = _.strIsolateRightOrAll( instruction, aggregator.commandImplicitDelimeter );
  [ result.instructionArgument, result.secondInstructionName, result.secondInstructionArgument ] = splits;

  if( result.secondInstructionName === undefined )
  delete result.secondInstructionName;

  result.instructionArgument = _.strUnquote( result.instructionArgument.trim() );
  if( result.secondInstructionName )
  result.secondInstructionName = result.secondInstructionName.trim();
  if( result.secondInstructionArgument )
  result.secondInstructionArgument = result.secondInstructionArgument.trim();

  if( result.secondInstructionName )
  {
    result.secondInstructionName = _.strUnquote( result.secondInstructionName.trim() );
    result.secondInstruction = result.secondInstructionName + ' ' + result.secondInstructionArgument;
  }

  return result;
}

// --
// etc
// --

function withSubphraseExport_head( routine, args )
{
  let self = this;

  let o = args[ 0 ];

  if( !_.object.isBasic( o ) )
  o = { phrase : args[ 0 ] };

  _.assert( arguments.length === 2 );
  _.assert( args.length === 1 );
  _.routine.options_( routine, o );

  return o;
}

//

function withSubphraseExportToStructure_body( o )
{
  let aggregator = this;

  _.assert( arguments.length === 1 );

  let subphraseDescriptorArray;
  if( _.strEnds( o.phrase, '.' ) )
  {
    subphraseDescriptorArray = commandsWithSubphraseGet();
  }
  else
  {
    subphraseDescriptorArray = commandsWithPhraseGet();
    if( !subphraseDescriptorArray )
    subphraseDescriptorArray = commandsWithSubphraseGet();
  }

  _.assert( _.arrayIs( subphraseDescriptorArray ) );

  if( !subphraseDescriptorArray.length )
  return '';

  let onDescriptorExportString = o.onDescriptorExportString
  if( !onDescriptorExportString )
  onDescriptorExportString = _.routine.join( aggregator, aggregator.commandExportString );
  let part1 = subphraseDescriptorArray.map( ( e ) =>
  {
    let phraseDescriptor = aggregator.vocabulary.phraseMap[ e.phrase ];
    _.assert( !!phraseDescriptor );
    return phraseDescriptor.phrase;
  });

  let longHint = !( o.phrase === '' || o.phrase === '.' );
  let part2 = subphraseDescriptorArray.map( ( e ) =>
  {
    let phraseDescriptor = aggregator.vocabulary.phraseMap[ e.phrase ];
    _.assert( !!phraseDescriptor );
    return onDescriptorExportString( phraseDescriptor, longHint );
  });
  let help = _.strJoin( [ _.ct.format( aggregator.vocabulary.defaultDelimeter, 'code' ), _.ct.format( part1, 'code' ), ' - ', part2 ] );

  return help;

  /* */

  function commandsWithSubphraseGet()
  {
    const o2 = _.mapOnly_( null, o, aggregator.vocabulary.withSubphrase.defaults );
    const subphraseDescriptorArray = aggregator.vocabulary.withSubphrase( o2 );
    return [ ... subphraseDescriptorArray ];
  }

  /* */

  function commandsWithPhraseGet()
  {
    const o2 = _.mapOnly_( null, o, aggregator.vocabulary.withPhrase.defaults );
    const phraseDescriptorArray = aggregator.vocabulary.withPhrase( o2 );
    if( phraseDescriptorArray )
    return _.array.as( phraseDescriptorArray );
  }
}

withSubphraseExportToStructure_body.defaults =
{
  phrase : null,
  delimeter : null,
  minimal : 0,
  onDescriptorExportString : null,
};

let withSubphraseExportToStructure = _.routine.unite( withSubphraseExport_head, withSubphraseExportToStructure_body );

//

function withSubphraseExportToString_body( o )
{
  const aggregator = this;
  const structure = aggregator.withSubphraseExportToStructure( o );
  const options =
  {
    levels : 2,
    wrap : 0,
    stringWrapper : '',
    multiline : 1,
    tab : '',
    dtab : ''
  };
  const exportString =  _.entity.exportString( structure, options );
  return `  ${ _.strLinesIndentation( exportString, '  ' ) }`;
}

withSubphraseExportToString_body.defaults = Object.create( withSubphraseExportToStructure.defaults );

let withSubphraseExportToString = _.routine.unite( withSubphraseExport_head, withSubphraseExportToString_body );

//

function _help( o )
{
  let aggregator = this;
  let logger = aggregator.logger || _global_.logger;

  if( _.strIs( arguments[ 0 ] ) )
  o = { argument : o }
  _.assert( arguments.length === 0 || arguments.length === 1 );
  _.routine.options( _help, o );

  if( o.argument )
  {
    logger.log();
    logger.log( aggregator.withSubphraseExportToString({ phrase : o.argument, minimal : 0, onDescriptorExportString }) );
    logger.up();

    let command = aggregator.vocabulary.withPhrase({ phrase : o.argument });

    // if( command )
    // {
    //   if( command.routine && command.properties )
    //   logger.log( aggregator.commandPropertiesExportString( command ) );
    // }
    // else
    if( !command )
    {
      logger.log( 'No command', o.argument );
    }

    logger.down();
    logger.log();

  }
  else
  {

    logger.log();
    logger.log( aggregator.withSubphraseExportToString( '' ) );
    logger.log();

  }

  return this;

  /* */

  function onDescriptorExportString( command, longHint )
  {
    let commandDescription = aggregator.commandExportString( command, longHint );
    let commandPropertiesDescription = '';
    if( command.routine && command.properties )
    commandPropertiesDescription = aggregator.commandPropertiesExportString( command );
    return _.strJoin( [ commandDescription, commandPropertiesDescription ], commandPropertiesDescription ? '\n' : '' );
  };
}

_help.defaults =
{
  argument : '',
};

// --
// predefined commands
// --

/*
  .help - Prints list of available commands with description
  .help commandName
    - Exact match - Prints description of command and properties.
    - Partial match - Prints list of commands that have provided commandName.
    - No match - Prints No command found.
*/

function _commandHelp( e )
{
  let aggregator = e.aggregator;
  let logger = aggregator.logger || _global_.logger;
  return aggregator._help({ argument : e.instructionArgument });
}

var command = _commandHelp.command = Object.create( null );
command.hint = 'Get help.';

// --
// handler
// --

function onError( err )
{
  let aggregator = this;
  /* qqq : cover the case. check appExitCode. test should be external ( launch process ) */
  if( aggregator.changingExitCode )
  _.process.exitCode( -1 );
  throw _.err( err || 'Error' );
}

//

function onSyntaxError( o )
{
  let aggregator = this;
  let err = _.errBrief( 'Illformed command', _.ct.format( _.strQuote( o.command ), 'code' ) );
  aggregator.logger.error( err );
  aggregator.onGetHelp();
  return aggregator.onError( err );
}

onSyntaxError.defaults =
{
  command : null,
}

//

function onGetHelp()
{
  let aggregator = this;
  _.assert( arguments.length === 0, 'Expects no arguments' );
  if( aggregator.vocabulary.phraseMap.help )
  {
    aggregator.instructionPerform({ command : '.help' });
  }
  else
  {
    aggregator._help();
  }
}

//

function onAmbiguity( o )
{
  let aggregator = this;
  let err = _.errBrief( 'Ambiguity', _.ct.format( _.strQuote( o.commandName ), 'code' ) );

  aggregator.logger.log( 'Ambiguity. Did you mean?' );
  aggregator.logger.log( aggregator.withSubphraseExportToString( o.commandName ) );
  aggregator.logger.log( '' );

  return aggregator.onError( err );
}

onAmbiguity.defaults =
{
  ... instructionPerformParsedLooking.defaults,
  subphrasesDescriptorArray : null,
}

//

function onUnknownCommandError( o )
{
  let aggregator = this;
  let s = 'Unknown command ' + _.strQuote( o.commandName );
  if( aggregator.vocabulary.phraseMap[ 'help' ] )
  s += '\nTry ".help"';
  return aggregator.onError( _.errBrief( s ) );
  // return aggregator.onError( _.err( s ) ); /* Dmytro : the behaviour of routine was changed in new code. Previous code : throw _.errBrief( s ); */
}

onUnknownCommandError.defaults =
{
  ... instructionPerformParsedLooking.defaults,
}

//

function onPrintCommands()
{
  let aggregator = this;

  _.assert( arguments.length === 0, 'Expects no arguments' );

  aggregator.logger.log();
  aggregator.logger.log( aggregator.withSubphraseExportToString( '' ) );
  aggregator.logger.log();

}

// --
// command
// --

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
  let aggregator = this;

  _.assert( !aggregator.formed, 'Command aggregator is already formed' );
  _.assert( arguments.length === 1 );

  if( !aggregator.vocabulary )
  aggregator._formVocabulary();

  commands = aggregator._commandMapFrom( commands );
  aggregator._commandMapValidate( commands );
  aggregator.vocabulary.phrasesAdd( commands );

  return aggregator;
}

//

function commandExportString( command, longHint )
{
  let aggregator = this;
  _.assert( aggregator.commandIs( command ) );

  if( longHint && command.longHint )
  return command.longHint;
  return command.hint || command.longHint || _.strCapitalize( command.phrase + '.' );
}

//

function commandPropertiesExportString( command )
{
  let aggregator = this;
  let routine = command.routine;
  let properties = command.properties;
  let keys = _.props.keys( properties )
  let hints = _.props.vals( properties );

  if( command.propertiesAliases )
  {
    let usedAliases = Object.create( null );
    _.assert( _.object.isBasic( command.propertiesAliases ) );
    for( let propName in command.propertiesAliases )
    {
      let aliases = _.array.as( command.propertiesAliases[ propName ] );
      _.assert( aliases.length >= 1 );
      aliases.forEach( ( alias ) =>
      {
        _.assert( !usedAliases[ alias ], `Alias ${alias} of property ${propName} is already in use.` )
        let hint = properties[ propName ];
        let propIndex = keys.indexOf( propName );
        keys.splice( propIndex, 0, alias );
        hints.splice( propIndex, 0, hint );
        usedAliases[ alias ] = 1;
      })
    }
  }

  keys = _.ct.format( keys, 'code' );

  let help = _.strJoin( [ keys, ' : ', hints ] );
  return _.entity.exportString( help, { levels : 2, wrap : 0, stringWrapper : '', multiline : 1 } );
}

//

function commandFrom( src, phrase )
{
  let aggregator = this;
  _.assert( arguments.length === 2 );
  _.assert( phrase === null || phrase === src.phrase );
  aggregator.commandValidate( src );
  return src;
}

//

function commandIs( src )
{
  if( !_.aux.is( src ) )
  return false;
  if( !_.strIs( src.phrase ) )
  return false;
  // if( !src.executable )
  // return false;
  return true;
}

// //
//
// function commandIs( command )
// {
//   if( !_.aux.is( command ) )
//   return false;
//   if( command.routine === undefined )
//   return false;
//   if( command.phrase === undefined )
//   return false;
//   return true;
// }

//

function commandLook( o )
{
  let aggregator = this;

  _.routine.options( commandLook, o );
  _.assert( _.strIs( o.commandName ) );
  _.assert( arguments.length === 1 );

  /* */

  let command = aggregator.vocabulary.withPhrase
  ({
    phrase : _.strRemoveBegin( o.commandName, aggregator.delimeter || '' ),
    normalize : 1
  });
  // let command = aggregator.vocabulary.withPhrase( o.commandName );

  if( o.withHandlers )
  if( !command )
  {
    let subphrasesDescriptorSet = aggregator.vocabulary.withSubphrase( o.commandName );
    if( subphrasesDescriptorSet.size )
    {
      let e = _.mapExtend( null, o );
      e.subphrasesDescriptorArray = subphrasesDescriptorSet;
      aggregator.onAmbiguity( e );
      return null;
    }
    else
    {
      aggregator.onUnknownCommandError( o );
      return null;
    }
    // let subphrasesDescriptorArray = aggregator.vocabulary.withSubphrase( o.commandName );
    // if( subphrasesDescriptorArray.length )
    // {
    //   let e = _.mapExtend( null, o );
    //   e.subphrasesDescriptorArray = subphrasesDescriptorArray;
    //   aggregator.onAmbiguity( e );
    //   return null;
    // }
    // else
    // {
    //   aggregator.onUnknownCommandError( o );
    //   return null;
    // }
    // if( !subphrasesDescriptorArray.length )
    // {
    //   aggregator.onUnknownCommandError( o );
    //   return null;
    // }
    // else
    // {
    //   let e = _.mapExtend( null, o );
    //   e.subphrasesDescriptorArray = subphrasesDescriptorArray;
    //   aggregator.onAmbiguity( e );
    //   return null;
    // }
  }

  return command || null;
}

commandLook.defaults =
{
  commandName : null,
  withHandlers : 1,
}

//

function commandValidate( command )
{
  let aggregator = this;
  _.assert( aggregator.commandIs( command ), 'Not a command' );
  _.assert( _.routineIs( command.routine ) );
  _.assert( command.routine.command === command );
  _.assert( _.strDefined( command.phrase ) );
  _.assert( command.aggregator === undefined || command.aggregator === aggregator );
  if( _.routineIs( command.routine ) )
  _.map.assertHasOnly( command.routine, aggregator.CommandRoutineFields, 'Command routine should not have redundant fields' );
  _.map.assertHasOnly( command, aggregator.CommandNormalFields, 'Command should not have' );
  return true;
}

//

function _commandMapValidate( commandMap )
{
  let aggregator = this;
  _.assert( _.mapIs( commandMap ) );
  for( let k in commandMap )
  {
    let command = commandMap[ k ]
    aggregator.commandValidate( command );
  }
  return commandMap;
}

//

function _commandPreform( command, commandRoutine, commandPhrase )
{
  let aggregator = this;

  if( commandRoutine === null )
  commandRoutine = command.routine || command.e;
  if( command === null )
  command = commandRoutine.command || Object.create( null );

  if( command.phrase )
  command.phrase = aggregator.vocabulary.phraseNormalize( command.phrase );
  if( commandPhrase )
  commandPhrase = aggregator.vocabulary.phraseNormalize( commandPhrase );
  commandPhrase = commandPhrase || command.phrase || ( commandRoutine.command ? commandRoutine.command.phrase : null ) || null;

  if( commandRoutine && commandRoutine.command )
  if( command !== commandRoutine.command )
  {
    _.assert( _.aux.is( commandRoutine.command ) );
    if( commandRoutine.command.phrase )
    commandRoutine.command.phrase = aggregator.vocabulary.phraseNormalize( commandRoutine.command.phrase );
    for( let k in commandRoutine.command )
    {
      _.assert
      (
        !_.props.has( command, k ) || command[ k ] === commandRoutine.command[ k ]
        , () => `Inconsistent field "${k}" of command "${commandPhrase}"`
      );
      command[ k ] = commandRoutine.command[ k ];
    }
    delete commandRoutine.command;
  }

  /* qqq : fill in asserts explanations */
  _.assert
  (
    !command.aggregator,
    () => `Command "${command.phrase}" already associated with a command aggregator.`
    + ` Each Command should be used only once.`
  );
  _.assert( _.routine.is( commandRoutine ), `Command "${commandPhrase}" does not have defined routine.` );
  _.assert( _.aux.is( command ) );
  _.assert( !_.props.has( command, 'ro' ) || commandRoutine === command.ro ); /* xxx : rename e to ro? */
  _.assert( !_.props.has( command, 'routine' ) || commandRoutine === command.routine );
  _.assert
  (
    !_.props.has( command, 'phrase' ) || commandPhrase === command.phrase,
    () => `Command ${commandPhrase} has phrases mismatch ${commandPhrase} <> ${command.phrase}`
  );
  _.assert( !_.props.own( commandRoutine, 'command' ) || commandRoutine.command === command );
  _.map.assertHasOnly( command, aggregator.CommandAllFields );

  if( commandPhrase )
  command.phrase = commandPhrase;
  command.routine = commandRoutine;
  commandRoutine.command = command;
  aggregator._CommandShortFiledsToLongFields( command, command );

  return command;
}

//

function _commandMapFrom( commandMap )
{
  let aggregator = this;
  let result = Object.create( null );
  let visited = new Set();

  if( _.aux.is( commandMap ) )
  {
    for( let k in commandMap )
    {
      let command = commandMap[ k ];
      let commandRoutine = command;

      if( _.routine.is( commandRoutine ) )
      command = null;
      else
      commandRoutine = command.ro || command.routine;

      let commandPhrase = aggregator.vocabulary.phraseNormalize( k );
      command = aggregator._commandPreform( command, commandRoutine, commandPhrase );
      command.aggregator = aggregator;
      aggregator.commandValidate( command );

      _.assert
      (
        !visited.has( command.routine ),
        `Duplication of command "${command.phrase}"`
      );
      visited.add( command.routine );

      result[ command.phrase ] = command;
    }
  }
  else if( _.longIs( commandMap ) )
  {
    for( let k = 0 ; k < commandMap.length ; k++ )
    {
      let command = commandMap[ k ];
      let commandRoutine = command;
      if( _.routine.is( commandRoutine ) )
      command = null;
      else
      commandRoutine = command.ro || command.routine;

      command = aggregator._commandPreform( command, commandRoutine );
      command.aggregator = aggregator;
      aggregator.commandValidate( command );

      _.assert
      (
        !visited.has( command.routine ),
        `Duplication of command "${command.phrase}"`
      );
      visited.add( command.routine );

      result[ command.phrase ] = command;
    }
  }
  else _.assert( 0 );

  _.assert( _.aux.is( result ) );

  return result;
}

//

function _CommandShortFiledsToLongFields( dst, fields )
{
  _.assert( arguments.length === 2 );
  let filter = Self.CommandShortToLongFields;
  for( let k in fields )
  {
    if( _.props.has( filter, k ) )
    {
      _.assert
      (
        !_.props.has( dst, filter[ k ] ) || dst[ filter[ k ] ] === fields[ k ]
        , () => `Inconsistent field "${k}" of command "${commandPhraseGet()}"`
      );
      _.assert( !_.props.has( dst, filter[ k ] ) || dst[ filter[ k ] ] === fields[ k ] );
      dst[ filter[ k ] ] = fields[ k ];
      delete fields[ k ];
    }
  }

  function commandPhraseGet()
  {
    return dst.phrase || ( dst.command ? dst.command.phrase : null ) || null;
  }
}

// --
//
// --

let CommandRoutineFields =
{

  defaults : null,
  command : null,

  // hint : null,
  // longHint : null,
  // commandPhrase : null,
  // commandSubjectHint : null,
  // commandProperties : null,
  // commandPropertiesAliases : null,
  // routine : null,

  // executable

}

let CommandNormalFields =
{
  hint : null,
  longHint : null,
  phrase : null,
  subjectHint : null,
  properties : null,
  propertiesAliases : null,
  routine : null,
  aggregator : null,
}

let CommandShortFields =
{
  ro : null,
  h : null,
  lh : null,
}

let CommandAllFields =
{
  ... CommandNormalFields,
  ... CommandShortFields,
}

let CommandShortToLongFields =
{
  ro : 'routine',
  h : 'hint',
  lh : 'longHint',
}

let Composes =
{
  basePath : null,
  commandPrefix : '',
  delimeter : _.define.own([ '.', ' ' ]),
  commandExplicitDelimeter : ';',
  commandImplicitDelimeter : _.define.own( /(\s|^)\.\w[\w\.]*[^ \\\/\*\?](\s|$)/ ),
  // commandImplicitDelimeter : _.define.own( /(\s|^)\.(?:(?:\w[^ ]+))/ ),
  // commandImplicitDelimeter : _.define.own( /(\s|^)\.(?:(?:\w[^ ]*)|$)/ ), /* yyy */
  commandsExplicitDelimiting : 1,
  commandsImplicitDelimiting : 0, /* xxx : qqq : for Dmytro : ask. set to 1 by default */
  propertiesMapParsing : 0,
  severalValues : 1,
  withHelp : 1,
  changingExitCode : 1,
}

let Aggregates =
{
  onError,
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
  Exec,
  // commandIs,
  _CommandShortFiledsToLongFields,
  CommandRoutineFields,
  CommandNormalFields,
  CommandShortFields,
  CommandAllFields,
  CommandShortToLongFields,
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

  // inter

  init,
  form,
  _formVocabulary,
  extend,
  supplement,
  exec,
  Exec,

  // run

  programPerform,

  instructionsPerform,
  instructionPerform,
  instructionPerformParsedLooking,
  instructionPerformParsedFound,

  // parse

  instructionsParse,
  instructionParse,

  instructionIsolateSecondFromArgument : instructionIsolateSecondFromArgumentLeft,
  instructionIsolateSecondFromArgumentLeft,
  instructionIsolateSecondFromArgumentRight,

  // etc

  withSubphraseExportToStructure,
  withSubphraseExportToString,
  _help,

  // predefined commands

  _commandHelp,

  // handler

  onError,
  onSyntaxError,
  onAmbiguity,
  onGetHelp,
  onPrintCommands,

  // command

  commandsAdd,
  commandExportString,
  commandPropertiesExportString,
  commandFrom,
  commandIs,
  commandLook,
  commandValidate,
  _commandMapValidate,
  _commandPreform,
  _commandMapFrom,
  _CommandShortFiledsToLongFields,

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

//

_[ Self.shortName ] = Self;
if( typeof module !== 'undefined' )
module[ 'exports' ] = Self;

})();
