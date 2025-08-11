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

--* Maids
local function GetHierarchyChain(Script:Script)
  local Hierarchy:{Instance} = {  };
  local CurrentParent = Script;
  local index = 1;
  while not (CurrentParent == game) do
    Hierarchy[index] = CurrentParent;
    index = index + 1;
    CurrentParent = CurrentParent.Parent;
  end
  return Hierarchy; -- index 1 = script, index #Hieararchy = Service
end
local function HierarchyToPath(Hieararchy:{Instance}) --! THIS DO NOT INCLUDE THE SCRIPT ITSELF
  local PATH = ProjectName .. "/src/"
  for index = #Hieararchy, 2 , -1 do
    PATH = PATH .. Hieararchy[index].Name .. "/";
  end
  return PATH;
end
local function PrintHierarchy(Hierarchy:{Instance})
  local Path = ""
  for index = #Hierarchy, 1 , -1 do
    Path = Path .. Hierarchy[index].Name .. "/";
  end
  print("Chain: ", Path);
end
local function GetScriptExtension(Script:Script) 
      local FrontString
      if Script.ClassName == "Script" then
        FrontString = ".server.lua";
      elseif Script:IsA("LocalScript") then
        FrontString = ".client.lua";
      elseif Script:IsA("ModuleScript") then
        FrontString = ".lua";
      else
        error("Unknown Script Type: " .. Script:GetFullName());
      end
  return FrontString;
end
local function ReturnObjectByHierarchy(Hieararchy:{Instance})
  print("GET THIS GUY: ");
  PrintHierarchy(Hieararchy);
  local Object = game;
  for index = #Hieararchy, 1 , -1 do
    print("Trying: " , Hieararchy[index].Name);
    Object = Object[Hieararchy[index].Name];
  end
  return Object;
end
local function sliceTable(first , last , Table:table)
  local MetaTable = {  };
  for index = first, last do
    MetaTable[#MetaTable+1] = Table[index] 
  end
  return MetaTable
end

local function AddScript(Script:Script)
  local Hierarchy = GetHierarchyChain(Script);
  local CurrentPath = ProjectName .. "/src/" .. Hierarchy[#Hierarchy].Name; --* Service

  for index = #Hierarchy - 1, 1 , - 1 do
    if Hierarchy[index] == Script then --* Create Scripts 
      local PATH = HierarchyToPath(Hierarchy)
      local FileExtension = GetScriptExtension(Script);

      if #Script:GetChildren() > 0 then
        fs.writeDir(PATH .. Script.Name);
        fs.writeFile(PATH ..  Script.Name .. "/init" .. FileExtension, Script.Source);
        fs.writeFile(PATH .. Script.Name .."/init.meta.json", `\{ \n   "ignoreUnknownInstances": true \n}`); 
      else
        fs.writeFile(PATH .. "/" .. Script.Name .. FileExtension , Script.Source)
      end
      break;
    end

    CurrentPath = CurrentPath .. "/" .. Hierarchy[index].Name;
    fs.writeDir(CurrentPath);

   if not fs.isFile(CurrentPath .. "/init.meta.json") then  
    local SlicedTable = sliceTable(index , #Hierarchy, Hierarchy);
    local Object = ReturnObjectByHierarchy(SlicedTable);
    fs.writeFile(CurrentPath .. "/init.meta.json" , `\{\n"className": "{Object.ClassName}",\n"ignoreUnknownInstances": true \n}`); --* i need to check if init.meta.json exist already or not
   end
  
  end
end

print("\n---------------------------SCRIPTS---------------------------");

local x = 0;
for _ , Instance:Instance in ipairs(Data) do
    local Path = Instance:GetFullName();
    if Instance:IsA("Script") or Instance.ClassName == "ModuleScript" then
        --print(Path);
        AddScript(Instance);

        
        continue;
    end
end