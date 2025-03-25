import os, osproc, strutils, json, re, tables

type
  Target = object
    patterns: seq[string]
    associations: Table[string, string]

  Xon = object
    contexts: Table[string, bool]
    placeholder, mimeQuery: string
    targets: seq[Target]

# Substitute the placeholder with the quoted filePath in a command string.
proc substitute(cmd, placeholder, filePath: string): string =
  cmd.replace(placeholder, "\"" & filePath & "\"")

# Load and parse a JSON configuration file.
proc loadConfig(filePath: string): JsonNode =
  if not fileExists(filePath):
    quit("Failed to load config file: " & filePath)
  parseJson(readFile(filePath))

# Create a new Xon instance from the JSON configuration.
proc newXon(config: JsonNode): Xon =
  var x = Xon(
    placeholder: if config.hasKey("placeholder"):
                   config["placeholder"].getStr
                 else:
                   "//f",
    mimeQuery: if config.hasKey("mime_query"):
                 config["mime_query"].getStr
               else:
                 "file --brief --mime-type //f",
    contexts: initTable[string, bool](),
    targets: @[]
  )

  if config.hasKey("contexts"):
    for key, value in config["contexts"].fields:
      x.contexts[key] = value.getBool
  else:
    x.contexts["default"] = true

  if config.hasKey("targets"):
    for targetNode in config["targets"].items:
      var t = Target(patterns: @[], associations: initTable[string, string]())
      for pat in targetNode["patterns"].items:
        t.patterns.add(pat.getStr)
      for ctx, cmd in targetNode["associations"].fields:
        t.associations[ctx] = cmd.getStr
      x.targets.add(t)
  x

# Launch the appropriate command based on the file or URI.
proc launch(x: Xon; fileOrURI: string) =
  var filePath = fileOrURI
  # Remove the "file://" prefix if present.
  if filePath.startsWith("file://"):
    filePath = filePath.substr(7)

  var mimeOrURI: string
  # If the file exists, determine its MIME type.
  if fileExists(filePath):
    let mimeCmd = substitute(x.mimeQuery, x.placeholder, filePath)
    # Use execProcess which returns the command output as a string.
    mimeOrURI = execProcess(mimeCmd).strip()
  else:
    mimeOrURI = fileOrURI

  for target in x.targets:
    for pat in target.patterns:
      # Build the regex from a string for case-insensitive match.
      if mimeOrURI.match(re("(?i)" & pat)):
        for context, cmd in target.associations.pairs:
          # Check if the key exists.
          if (context in x.contexts) and x.contexts[context]:
            let finalCmd = substitute(cmd, x.placeholder, filePath)
            discard execCmd(finalCmd)
            return

when isMainModule:
  # Expect at least two arguments: config file and file/URI.
  if paramCount() < 2:
    quit("Usage: " & paramStr(0) & " <config.json> <fileOrURI>")
  
  let config = loadConfig(paramStr(1))
  let app = newXon(config)
  launch(app, paramStr(2))
