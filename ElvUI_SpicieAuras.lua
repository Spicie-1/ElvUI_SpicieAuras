-- Debuff Aura Sorting ElvUI Plugin
-- Author: Spicie
-- Version: 1.0.0

local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local MyPlugin = E:NewModule('ElvUI_SpicieAuras', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0'); --Create a plugin within ElvUI and adopt AceHook-3.0, AceEvent-3.0 and AceTimer-3.0. We can make use of these later.
local EP = LibStub("LibElvUIPlugin-1.0") --We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.
local addonName, addonTable = ... --See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2
local UF = E:GetModule('UnitFrames')
local A = E:GetModule('Auras')
local PA = E:GetModule('PrivateAuras')
local LSM = E.Libs.LSM
local ElvUF = E.oUF

--Default options
P["ElvUI_SpicieAuras"] = {
    ["PriorityList"] = [[
-- Destro Warlock
Havoc = 100
Immolate = 99
Conflagrate = 98
Eradication = 90

-- Affliction Warlock
Soul Rot = 100
Haunt = 99
Seed of Corruption = 95
Unstable Affliction = 94
Agony = 93
Corruption = 92
Siphon Life = 91
Vile Taint = 90
Drain Soul = 80
Drain Life = 80

-- All Warlock
Curse of Exhaustion = 50
Curse of Tongues = 50
Curse of Weakness = 50

-- Shadow Priest
Vampiric Touch = 100
Shadow Word: Pain = 95
Mind Flay = 25

-- Rogue
Marked for Death = 100
Sap = 99

-- Druid
Rip = 100
Moonfire = 90
Sunfire = 89

-- Paladin
Blade of Justice = 100
Judgement = 90

-- Demon Hunter
Sigil of Silence = 100
Sigil of Misery = 99
Frailty = 95
Sigil of Flame = 90

-- Shaman

-- Mage

-- Death Knight

-- Warrior

-- Hunter

-- Evoker

-- Monk
]],
}

-- Create a table to store the priority list
local priority = {}
--local priority = E.db.ElvUI_SpicieAuras.PriorityList

-- Function to parse the priority list string and convert it to a table
local function ParsePriorityList(listString)
    local list = {}
    for line in listString:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$") -- Trim whitespace from both ends
        if not line:match("^%s*%-%-") then
            local spell, prio = line:match("^(.-)%s*=%s*(%d+)")
            if spell and prio then
                list[spell] = tonumber(prio)
            end
        end
    end
    return list
end

-- Initialize priority list with default values
local function InitializePriorityList()
    if not E.db.ElvUI_SpicieAuras.PriorityList then
        E.db.ElvUI_SpicieAuras.PriorityList = P["ElvUI_SpicieAuras"].PriorityList
    end
    priority = ParsePriorityList(E.db.ElvUI_SpicieAuras.PriorityList)
    --[==[]
    print("Initalizing Prio List")
    for k, v in pairs(priority) do
        print(k, "=", v)
    end
    --]==]
end

local function UpdatePriorityList(value)
    E.db.ElvUI_SpicieAuras.PriorityList = value -- Save the updated list to the database
    priority = ParsePriorityList(E.db.ElvUI_SpicieAuras.PriorityList)
    --[==[]
    print("Updated Priority List:")
    for spell, prio in pairs(priority) do
        print(spell, "=", prio)
    end
    --]==]
end

-- Function to reset the priority list to default values
local function ResetPriorityList()
    -- Reset to default
    E.db.ElvUI_SpicieAuras.PriorityList = P["ElvUI_SpicieAuras"].PriorityList
    -- Update the internal priority table
    UpdatePriorityList(E.db.ElvUI_SpicieAuras.PriorityList)
    print("|cffff0000Priority List|r has been reset to |cff0066ffdefault|r values.")
end

--This function inserts our GUI table into the ElvUI Config. You can read about AceConfig here: http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
function MyPlugin:InsertOptions()
	E.Options.args.MyPlugin = {
		order = 100,
		type = "group",
		name = "|cff00ff00Spicie Auras|r",
		args = {
            MainHeading = {
                order = 1,
                type = "header",
                name = "|cff00ff00Spicie Auras|r Priority Sorting Plugin",
            },
            PluginDesc = {
                order = 2,
                type = "description",
                fontSize = "large",
                name = [[
    Enable '|cff00ff00Spicies Priority Based|r' sort method in the |cff0066ffdebuffs|r section within |cffff0000UnitFrames|r > |cffff0000Individual/Group Units|r

    Currently supported unitframes are:
    - |cffff0000Target|r
    - |cffff0000Focus|r
    - |cffff0000Boss|r
                ]],
                width = "full",
            },
            PrioHeading = {
                order = 3,
                type = "header",
                name = "Priority List"
            },
            PrioDesc = {
                order = 4,
                type = "description",
                fontSize = "medium",
                name = [[
Enter each |cff0066ffSpell Name|r or |cff0066ff Spell Id|r and its priority on a new line
in the format '|cffff0000Spell Name = Priority|r'.

Examples:
|cff0066ffAgony|r = 98
|cff0066ffSoul Rot|r = 97
|cff0066ff172|r = 90

Comments are marked by starting the line with '|cff00cc00--|r'

Example:
|cff00cc00-- Destruction Warlock|r

The same number priority spells will be sorted by descending time remaining. Spells not on the priority list will be sorted after the priority spells by descending time remaining.

                ]],
                width = 1.75,
            },
            PriorityList = {
                order = 5,
                type = "input",
                name = "Priority List",
                width = 1.75,
                multiline = 31,
                get = function(info)
                    return E.db.ElvUI_SpicieAuras.PriorityList
                end,
                set = function(info, value)
                    return UpdatePriorityList(value)
                end,
            },
            ResetButtonLineBreak = {
                order = 24,
                type = "header",
                name = "Reset Plugin Options"
            },
            ResetPriorityList = {
                order = 25,
                type = "execute",
                name = "Reset Priority List to Defaults",
                confirm = true,
                func = function()
                    ResetPriorityList()
                end,
            },
		},
	}
end

-- Not currently used for anything
--[==[
--Function we can call when a setting changes.
function MyPlugin:Update()
	local enabled = E.db.ElvUI_SpicieAuras.TargetPriorityAuraSorting

	if enabled then
		print("Debuff priorty sorting enabled")
	else
		print("Debuff priorty sorting disabled")
	end
end
--]==]

local function InsertPrioSortOption()
    E.Options.args.unitframe.args.individualUnits.args.target.args.debuffs.args.sortMethod.values.SPICIESORT = "Spicie's Priority Based"
    E.Options.args.unitframe.args.individualUnits.args.focus.args.debuffs.args.sortMethod.values.SPICIESORT = "Spicie's Priority Based"
    E.Options.args.unitframe.args.groupUnits.args.boss.args.debuffs.args.sortMethod.values.SPICIESORT = "Spicie's Priority Based"
end

-- Event handler for ADDON_LOADED
function MyPlugin:OnElvOptLoaded(event, addon)
    if addon == "ElvUI_Options" then
        InsertPrioSortOption()
        self:InsertOptions()
        self:UnregisterEvent("ADDON_LOADED")
    end
end

local function SpicieSortMethod(a, b, dir)
    local p1 = priority[a.spellID] or priority[a.name] or 0
    local p2 = priority[b.spellID] or priority[b.name] or 0
    --print("SpicieSortMethod: Comparing", a.name, "with priority", p1, "and", b.name, "with priority", p2)
    -- Sort by priority first
    if p1 ~= p2 then
        return p1 > p2
    else
        -- Sort by time remaining
        local aura1 = a.expiration or -math.huge
        local aura2 = b.expiration or -math.huge
        if dir == 'DESCENDING' then
            return aura1 > aura2
        else
            -- Ascending order
            return aura1 < aura2
        end
    end
end

-- Insert the custom sort function into UF.SortAuraFuncs
local function InsertSpicieSortMethod()
    UF.SortAuraFuncs.SPICIESORT = SpicieSortMethod
end

-- Hook into A:UpdateHeader to ensure the custom sort method is applied
local function CustomUpdateHeader(self, header)
    if header.filter == 'HARMFUL' and header.db and header.db.sortMethod == "SPICIESORT" then
        header:SetAttribute('sortMethod', "SPICIESORT")
    end
end

function MyPlugin:Initialize()
    -- Initialize the database with default values
    E.db.ElvUI_SpicieAuras.PriorityList = E.db.ElvUI_SpicieAuras.PriorityList or P["ElvUI_SpicieAuras"].PriorityList
    -- Initalize priority list
    InitializePriorityList()

    -- Register plugin so options are properly inserted when config is loaded
    EP:RegisterPlugin(addonName, function()
        MyPlugin.InsertOptions()
        self:RegisterEvent("ADDON_LOADED", "OnElvOptLoaded")
        InsertPrioSortOption()
    end)

    -- Insert the custom sort method
    InsertSpicieSortMethod()

    -- Hook into ElvUI's UpdateHeader function
    hooksecurefunc(A, 'UpdateHeader', CustomUpdateHeader)

    -- Plugin welcome message / finished loading
    self:ScheduleTimer(function()
        E:Print("|cff00ff00Spicie Auras Plugin Loaded!|r")
    end, 3)
end

E:RegisterModule(MyPlugin:GetName()) --Register the module with ElvUI. ElvUI will now call MyPlugin:Initialize() when ElvUI is ready to load our plugin.
