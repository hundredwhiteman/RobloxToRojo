warn("This Script Can NOT Handle Assets that has special characters in their names, such as / or \\, . ,  etc. It will crash if it encounters such an asset. This is a limitation of the current implementation.")
warn("This Script Can NOT Handle If There Is Two Assets with the Same Name and Parent, it will overwrite the previous one. This is a limitation of the current implementation.")
local process = require("@lune/process")


local args = process.args;
if #args < 3 or args[2] ~= "-o" then
    
    print("\n\nArgument 1: " , args[1]);
    print("Argument 2: " , args[2]);
    print("Argument 3: " , args[3]);
    assert(false, "Invalid arguments. Expected usage: lune run PlaceToRojo.luau PLACE_PATH -o ProjectName");
end
local PLACE_PATH = args[1]
local ProjectName = args[3]::string


local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Content = fs.readFile(PLACE_PATH);
local game = roblox.deserializePlace(Content);

local Data = game:GetDescendants();
local JsonStructure = `\{\n"name": "{ProjectName}",\n`..
[[
"tree": {
    "$className": "DataModel",

    "ReplicatedStorage": {
      "$path": "src/ReplicatedStorage",
      "$ignoreUnknownInstances": true
    },

    "ServerScriptService": {
      "$path": "src/ServerScriptService",
      "$ignoreUnknownInstances": true
    },

    "StarterPlayer": {
      "StarterPlayerScripts": {
        "$path": "src/StarterPlayer/StarterPlayerScripts",
        "$ignoreUnknownInstances": true
      },
      "StarterCharacterScripts": {
        "$path": "src/StarterPlayer/StarterCharacterScripts",
        "$ignoreUnknownInstances": true
      },
      "$ignoreUnknownInstances": true
    },

    "Workspace": {
      "$path": "src/Workspace",
      "$ignoreUnknownInstances": true 
    },

    "ServerStorage": {
      "$path": "src/ServerStorage",
      "$ignoreUnknownInstances": true 
    },

    "StarterGui": {
      "$path": "src/StarterGui",
      "$ignoreUnknownInstances": true 
    },

    "StarterPack": {
      "$path": "src/StarterPack",
      "$ignoreUnknownInstances": true 
    },

    "ReplicatedFirst": {
      "$path": "src/ReplicatedFirst",
      "$ignoreUnknownInstances": true 
    },
    "TestService": {
      "$path": "src/TestService",
      "$ignoreUnknownInstances": true 
    }
 }
}
]];

local function CreateServices(src:string)
      fs.writeDir(src .. "/StarterPlayer");
      fs.writeDir(src .. "/StarterPlayer/StarterPlayerScripts");
      fs.writeDir(src .. "/StarterPlayer/StarterCharacterScripts");
      fs.writeDir(src .. "/ServerStorage");
      fs.writeDir(src .. "/StarterGui");
      fs.writeDir(src .. "/StarterPack");
      fs.writeDir(src .. "/ReplicatedFirst");
      fs.writeDir(src .. "/Workspace");
      fs.writeDir(src .. "/ServerScriptService");
      fs.writeDir(src .. "/ReplicatedStorage"); 
      fs.writeDir(src .. "/TestService");
end

local function CreateProject()
    local src = ProjectName .. "/src";
    fs.writeDir(ProjectName);
    fs.writeFile(ProjectName .. "/default.project.json" , JsonStructure);

    CreateServices(src);

end

CreateProject();

local function AddScript(Script)
  local FullPath = Script:GetFullName();
  local Chain = string.split(FullPath, ".");
  local Path = table.concat(Chain, "/");
  local CurrentPath = Chain[1];
  print("Chain Length: ", #Chain);

  for i = 2, #Chain, 1 do
    CurrentPath = CurrentPath .. "/" .. Chain[i];
    
    if i == #Chain then
      local FrontString;
      if Script.ClassName == "Script" then
        FrontString = ".server.lua";
      elseif Script:IsA("LocalScript") then
        FrontString = ".client.lua";
      elseif Script:IsA("ModuleScript") then
        FrontString = ".lua";
      else
        error("Unknown Script Type: " .. Script:GetFullName());
      end

      fs.writeFile(ProjectName .. "/src/" .. Path .. FrontString, Script.Source);
      break;
    end
    fs.writeDir(ProjectName .. "/src/" .. CurrentPath);

    local Object = game;
    for j = 1, i, 1 do
      Object = Object[Chain[j]];
    end
    print("Object: ", Object);

    fs.writeFile(ProjectName .. "/src/" .. CurrentPath .. "/init.meta.json" , `\{\n"className": "{Object.ClassName}",\n"ignoreUnknownInstances": true \n}`);
    print("Creating Directory: ", CurrentPath);
  end

end

print("\n---------------------------SCRIPTS---------------------------");


for _ , Instance:Instance in ipairs(Data) do
    local Path = Instance:GetFullName();
    if Instance:IsA("Script") then
        print("Script: " , Instance , Path);
        AddScript(Instance);
        continue;
    end
end