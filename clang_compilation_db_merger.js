var path = require('path');
var fs = require('fs');

var args = processArgs();
var merged = merge(args);
writeOutput(args, merged);

function die(message) {
  console.error(message);
  process.exit();
}

function processArgs() {
  var usage = "Usage: source.json destination.json";
  if (process.argv.length != 4) {
    die(usage);
  }
  var srcPath = process.argv[2];
  var dstPath = process.argv[3];
  if (!srcPath.match(/\.json$/) || !dstPath.match(/\.json$/)) {
    die(usage);
  }
  var src = readDatabase(srcPath);
  var dst = readDatabase(dstPath);
  if (!src.length) {
    die("Source compilation database is empty: " + srcPath);
  }
  return { src: src, dst: dst, srcPath: srcPath, dstPath: dstPath };
}

function merge(args) {
  var src = args.src;
  var dst = args.dst;
  var files = {};
  for (var i in dst) {
    var item = dst[i];
    files[item.file] = item;
  }

  var stats = { entries: 0, added: 0, updated: 0 };
  for (var i in src) {
    var item = src[i];
    var file = item.file;
    var target = files[file];
    if (!target) {
      target = { file: file };
      dst.push(target);
      stats.added++;
    }
    if (target.command != item.command || target.directory != item.directory) {
      target.command = item.command;
      target.directory = item.directory;
      stats.updated++;
    }
    stats.entries++;
  }
  return { dst: dst, stats: stats };
}

function writeOutput(args, merged) {
  var stats = merged.stats;
  fs.writeFile(absPath(args.dstPath), JSON.stringify(merged.dst, null, 2), function(error) {
    if (error) {
      die(error);
    } else {
      console.log('Successfully merged (' +
          stats.entries + ' entries, ' +
          stats.added + ' new, ' +
          stats.updated + ' updated).');
    }
  });
}

function readDatabase(p) {
  var result;
  try {
   result = require(absPath(p));
  } finally {
    return Array.isArray(result) ? result : [];
  }
}

function absPath(p) {
  return path.resolve(process.cwd(), p);
}