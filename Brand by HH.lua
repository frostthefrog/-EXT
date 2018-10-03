local Addons = {"Brand"}
local Started = false
function OnLoad()
    if table.contains(Addons,myHero.charName) and Started == false then
		_G[myHero.charName]()
		Started = true
	end
end

local LocalAlly                     = myHero.team
local LocalJungle                   = 300
local LocalEnemy                    = LocalJungle - LocalAlly
local LocalMyHeroIsDead             = myHero.dead

local _atan                         = math.atan2
local _min                          = math.min
local _abs                          = math.abs
local _sqrt                         = math.sqrt
local _floor                        = math.floor
local _max                          = math.max
local _pow                          = math.pow
local _huge                         = math.huge
local _pi                           = math.pi
local _insert                       = table.insert
local _contains                     = table.contains
local _sort                         = table.sort
local _pairs                        = pairs
local _find                         = string.find
local _sub                          = string.sub
local _len                          = string.len

local LocalDrawLine					= Draw.Line;
local LocalDrawColor				= Draw.Color;
local LocalDrawCircle				= Draw.Circle;
local LocalDrawCircleMinimap        = Draw.CircleMinimap;
local LocalDrawText					= Draw.Text;
local LocalControlIsKeyDown			= Control.IsKeyDown;
local LocalControlMouseEvent		= Control.mouse_event;
local LocalControlSetCursorPos		= Control.SetCursorPos;
local LocalControlCastSpell         = Control.CastSpell;
local LocalControlKeyUp				= Control.KeyUp;
local LocalControlKeyDown			= Control.KeyDown;
local LocalControlMove			    = Control.Move;
local LocalGetTickCount             = GetTickCount;
local LocalGameCanUseSpell			= Game.CanUseSpell;
local LocalGameLatency				= Game.Latency;
local LocalGameTimer				= Game.Timer;
local LocalGameHeroCount 			= Game.HeroCount;
local LocalGameHero 				= Game.Hero;
local LocalGameMinionCount 			= Game.MinionCount;
local LocalGameMinion 				= Game.Minion;
local LocalGameTurretCount 			= Game.TurretCount;
local LocalGameTurret 				= Game.Turret;
local LocalGameWardCount 			= Game.WardCount;
local LocalGameWard 				= Game.Ward;
local LocalGameObjectCount 			= Game.ObjectCount;
local LocalGameObject				= Game.Object;
local LocalGameMissileCount 		= Game.MissileCount;
local LocalGameMissile				= Game.Missile;
local LocalGameParticleCount 		= Game.ParticleCount;
local LocalGameParticle				= Game.Particle;
local LocalGameIsChatOpen			= Game.IsChatOpen;
local LocalGameIsOnTop				= Game.IsOnTop;


function GetMode()
	if _G.SDK then
        if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
            return "Combo"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
            return "Harass"	
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then 
            return "Clear"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
            return "LastHit"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
            return "Flee"
        end
    else
        return GOS.GetMode()
    end
end

function GetDistance(p1, p2)
    return _sqrt(_pow((p2.x - p1.x),2) + _pow((p2.y - p1.y),2) + _pow((p2.z - p1.z),2))
end

function GetDistance2D(p1, p2)
    return _sqrt(_pow((p2.x - p1.x),2) + _pow((p2.y - p1.y),2))
end

function GetDistanceSqr(p1, p2)
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return (dx * dx + dz * dz)
end

function IsValidTarget(unit, range)
    if unit then
        return GetDistance(unit.pos, myHero.pos) <= range and unit.health > 0 and unit.isTargetable and unit.visible
    end
end

function HeroesAround(range, pos, team)
    local range = range or _huge
    local pos = pos or myHero.pos
    local team = team or LocalEnemy
    local Count = 0
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero and hero.team == team and not hero.dead and GetDistance(pos, hero.pos) < range then
			Count = Count + 1
		end
	end
    return Count
end

function MinionsAround(range, pos, team)
    local range = range or _huge
    local pos = pos or myHero.pos
    local team = team or LocalEnemy
    local Count = 0
	for i = 1, LocalGameMinionCount() do
		local minion = LocalGameMinion(i)
		if minion and minion.team == team and not minion.dead and GetDistance(pos, minion.pos) < range then
			Count = Count + 1
		end
	end
	return Count
end

function GetBestCircularFarmPos(range, radius)
	local BestPos = nil
	local MostHit = 0
	for i = 1, LocalGameMinionCount() do
		local minion = LocalGameMinion(i)
		if minion and minion.isEnemy and not minion.dead and GetDistance(minion.pos, myHero.pos) <= range then
			local Count = MinionsAround(radius, minion.pos, LocalEnemy)
			if Count > MostHit then
				MostHit = Count
				BestPos = minion.pos
			end
		end
	end
	return BestPos, MostHit
end

function ClosestMinion(range, pos, team)
    local range = range or _huge
    local pos = pos or myHero.pos
    local team = team or LocalEnemy
    local bestMinion = nil
    local closest = _huge
    for i = 1, LocalGameMinionCount() do
        local minion = LocalGameMinion(i)
        if minion and not minion.dead and GetDistance(minion.pos, pos) < range and minion.team == team then
            local Distance = GetDistance(minion.pos, pos)
            if Distance < closest then
                bestMinion = minion
                closest = Distance
            end
        end
    end
    return bestMinion
end

local castSpell = {state = 0, tick = LocalGetTickCount(), casting = LocalGetTickCount() - 1000, mouse = mousePos}
function CastSpell(spell, pos, range, delay)
    local range = range or _huge
    local delay = delay or 250
    local ticker = LocalGetTickCount()

	if castSpell.state == 0 and GetDistance(myHero.pos,pos) < range and ticker - castSpell.casting > delay + LocalGameLatency() and pos:ToScreen().onScreen then
		castSpell.state = 1
		castSpell.mouse = mousePos
		castSpell.tick = ticker
	end
	if castSpell.state == 1 then
		if ticker - castSpell.tick < LocalGameLatency() then
			LocalControlSetCursorPos(pos)
			LocalControlKeyDown(spell)
			LocalControlKeyUp(spell)
			castSpell.casting = ticker + delay
			DelayAction(function()
				if castSpell.state == 1 then
					LocalControlSetCursorPos(castSpell.mouse)
					castSpell.state = 0
				end
			end,LocalGameLatency()/1000)
		end
		if ticker - castSpell.casting > LocalGameLatency() then
			LocalControlSetCursorPos(castSpell.mouse)
			castSpell.state = 0
		end
	end
end

function GetPercentHP(unit)
    return 100 * unit.health / unit.maxHealth
end

function GetPercentMP(unit)
    return 100 * unit.mana / unit.maxMana
end

function GetItemSlot(unit, id)
    for i = ITEM_1, ITEM_7 do
        if unit:GetItemData(i).itemID == id then
            return i
        end
    end
    return 0 
end

function string.ends(String,End)
    return End == "" or _sub(String,-_len(End)) == End
end

function HasBuff(unit, buffname)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff.name == buffname and buff.count > 0 then 
            return true
        end
    end
    return false
end

function GotBuff(unit, buffname)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff.name == buffname and buff.count > 0 then 
            return buff.count
        end
    end
    return 0
end

function AffectedMobility(target,duration)
    local duration = duration or 0.1
    for i = 0, target.buffCount do
        local buff = target:GetBuff(i);
        if buff.count > 0 then
            if (buff.type == 5 or buff.type == 11 or buff.type == 18 or buff.type == 24 or buff.type == 28 or buff.type == 29 or buff.type == 31) and buff.duration > duration then
                return immobile
            end
            if (buff.type == 9 or buff.type == 10) and buff.duration > duration then
                return slow
            end
        end
    end
end

local importantspells = {
	'CaitlynAceintheHole',
	'ReapTheWhirlwind',
	'karthusfallenonecastsound',
	'katarinarsound',
	'Meditate',
	'missfortunebulletsound',
	'AbsoluteZero',
	'shenstandunitedlock',
	'Destiny',
	'VelkozR',
	'warwickrsound',
	'XerathRMissileWrapper'}

function SpellChannel(target,duration)
    local duration = duration or 0.1
    for i = 0, target.buffCount do
        local buff = target:GetBuff(i);
        if buff.count > 0 then
            if (buff.name:lower() == importantspells[i]) and buff.duration > duration then
                return true
            end
        end
    end
    return false
end

function Angle(p1, p2)
	local deltaPos = p1 - p2
	local angle = _atan(deltaPos.x, deltaPos.z) *  180 / _pi	
	if angle < 0 then angle = angle + 360 end
	return angle
end

local _movementHistory = {}
function TrackMoves(target)
	if not _movementHistory[target.charName] then
		_movementHistory[target.charName] = {}
		_movementHistory[target.charName]["EndPos"] = target.pathing.endPos
		_movementHistory[target.charName]["StartPos"] = target.pathing.endPos
		_movementHistory[target.charName]["PreviousAngle"] = 0
		_movementHistory[target.charName]["ChangedAt"] = LocalGameTimer()
	end
	
	if _movementHistory[target.charName]["EndPos"].x ~=target.pathing.endPos.x or _movementHistory[target.charName]["EndPos"].y ~=target.pathing.endPos.y or _movementHistory[target.charName]["EndPos"].z ~=target.pathing.endPos.z then				
		_movementHistory[target.charName]["PreviousAngle"] = Angle(Vector(_movementHistory[target.charName]["StartPos"].x, _movementHistory[target.charName]["StartPos"].y, _movementHistory[target.charName]["StartPos"].z), Vector(_movementHistory[target.charName]["EndPos"].x, _movementHistory[target.charName]["EndPos"].y, _movementHistory[target.charName]["EndPos"].z))
		_movementHistory[target.charName]["EndPos"] = target.pathing.endPos
		_movementHistory[target.charName]["StartPos"] = target.pos
		_movementHistory[target.charName]["ChangedAt"] = LocalGameTimer()
	end
	
end

function NewHitchance(source, target, range, delay, speed, radius, collision)
    local hitChance, aimPosition = HPred:GetHitchance(source.pos, target, range, delay, speed, radius, collision, nil)
    local aimPositionDistance = GetDistance(source.pos,aimPosition)
    local timeToHitAimPosition = (aimPositionDistance / speed) + delay
    local targetDistance = GetDistance(source.pos,target.pos)
	local timeToHitTarget = (targetDistance / speed) + delay
	
	TrackMoves(target)

    if aimPositionDistance > range then
        return 0
	end
	if hitChance and hitChance >= 1 then
    	if SpellChannel(target,timeToHitTarget) then
        	return 5
    	end
    	if AffectedMobility(target,timeToHitTarget) == immobile then
        	return 5
		end
		if target.activeSpell and target.activeSpell.valid then
			local escapeTime = radius / target.ms +  target.activeSpell.startTime + target.activeSpell.windup - LocalGameTimer()
			local escapeWindow = timeToHitAimPosition - escapeTime		
			if escapeWindow < 0.35 then
				return 4
			end
		end
    	if AffectedMobility(target,timeToHitAimPosition) == slow then
        	return 3
		end
		if _movementHistory and _movementHistory[target.charName] and LocalGameTimer() - _movementHistory[target.charName]["ChangedAt"] < 0.25 then
			hitChance = 2
		end
    	if timeToHitAimPosition < 0.35 then
        	return 2
    	end
		return 1
	end
    return 0
end

local DamageReductionTable = {
    ["Alistar"] = {buff = "Ferocious Howl", amount = function(target) return ({0.5, 0.4, 0.3})[target:GetSpellData(_R).level] end},
    ["Amumu"] = {buff = "Tantrum", amount = function(target) return ({2, 4, 6, 8, 10})[target:GetSpellData(_E).level] end, damageType = 1},  
    ["Annie"] = {buff = "MoltenShield", amount = function(target) return 1 - ({0.16,0.22,0.28,0.34,0.4})[target:GetSpellData(_E).level] end},
    ["Braum"] = {buff = "BraumShieldRaise", amount = function(target) return 1 - ({0.3, 0.325, 0.35, 0.375, 0.4})[target:GetSpellData(_E).level] end},
    ["Galio"] = {buff = "GalioIdolOfDurand", amount = function(target) return 0.5 end},
    ["Garen"] = {buff = "GarenW", amount = function(target) return 0.7 end},
    ["Gragas"] = {buff = "GragasWSelf", amount = function(target) return ({0.1, 0.12, 0.14, 0.16, 0.18})[target:GetSpellData(_W).level] end},
    ["Malzahar"] = {buff = "malzaharpassiveshield", amount = function(target) return 0.01 end}
}

function CalcPhysicalDamage(source, target, amount)
    local ArmorPenPercent = source.armorPenPercent
    local ArmorPenFlat = (0.4 + target.levelData.lvl / 30) * source.armorPen
    local BonusArmorPen = source.bonusArmorPenPercent
    if source.type == Obj_AI_Minion then
        ArmorPenPercent = 1
        ArmorPenFlat = 0
        BonusArmorPen = 1
    elseif source.type == Obj_AI_Turret then
        ArmorPenFlat = 0
        BonusArmorPen = 1
        if source.charName:find("3") or source.charName:find("4") then
            ArmorPenPercent = 0.25
        else
            ArmorPenPercent = 0.7
        end
    end
    if source.type == Obj_AI_Turret then
        if target.type == Obj_AI_Minion then
            amount = amount * 1.25
        if string.ends(target.charName, "MinionSiege") then
            amount = amount * 0.7
        end
            return amount
        end
    end
    local armor = target.armor
    local bonusArmor = target.bonusArmor
    local value = 100 / (100 + (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat)
    if armor < 0 then
        value = 2 - 100 / (100 - armor)
    elseif (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat < 0 then
        value = 1
    end
    return _max(0, _floor(DamageReductionMod(source, target, PassivePercentMod(source, target, value) * amount, 1)))
end

function CalcMagicalDamage(source, target, amount)
    local mr = target.magicResist
    local value = 100 / (100 + (mr * source.magicPenPercent) - source.magicPen)
    if mr < 0 then
        value = 2 - 100 / (100 - mr)
    elseif (mr * source.magicPenPercent) - source.magicPen < 0 then
        value = 1
    end
    return _max(0, _floor(DamageReductionMod(source, target, PassivePercentMod(source, target, value) * amount, 2)))
end

function DamageReductionMod(source,target,amount,DamageType)
    if source.type == Obj_AI_Hero then
        if GotBuff(source, "Exhaust") > 0 then
        amount = amount * 0.6
        end
    end
    if target.type == Obj_AI_Hero then
        for i = 0, target.buffCount do
            if target:GetBuff(i).count > 0 then
                local buff = target:GetBuff(i)
                if buff.name == "MasteryWardenOfTheDawn" then
                    amount = amount * (1 - (0.06 * buff.count))
                end
                if DamageReductionTable[target.charName] then
                    if buff.name == DamageReductionTable[target.charName].buff and (not DamageReductionTable[target.charName].damagetype or DamageReductionTable[target.charName].damagetype == DamageType) then
                        amount = amount * DamageReductionTable[target.charName].amount(target)
                    end
                end
                if target.charName == "Maokai" and source.type ~= Obj_AI_Turret then
                    if buff.name == "MaokaiDrainDefense" then
                        amount = amount * 0.8
                    end
                end
                if target.charName == "MasterYi" then
                    if buff.name == "Meditate" then
                        amount = amount - amount * ({0.5, 0.55, 0.6, 0.65, 0.7})[target:GetSpellData(_W).level] / (source.type == Obj_AI_Turret and 2 or 1)
                    end
                end
            end
        end
        if GetItemSlot(target, 1054) > 0 then
            amount = amount - 8
        end
        if target.charName == "Kassadin" and DamageType == 2 then
            amount = amount * 0.85
        end
    end
    return amount
end

function PassivePercentMod(source, target, amount, damageType)
    local SiegeMinionList = {"Red_Minion_MechCannon", "Blue_Minion_MechCannon"}
    local NormalMinionList = {"Red_Minion_Wizard", "Blue_Minion_Wizard", "Red_Minion_Basic", "Blue_Minion_Basic"}
    if source.type == Obj_AI_Turret then
        if _contains(SiegeMinionList, target.charName) then
            amount = amount * 0.7
        elseif _contains(NormalMinionList, target.charName) then
            amount = amount * 1.14285714285714
        end
    end
    if source.type == Obj_AI_Hero then 
        if target.type == Obj_AI_Hero then
            if (GetItemSlot(source, 3036) > 0 or GetItemSlot(source, 3034) > 0) and source.maxHealth < target.maxHealth and damageType == 1 then
                amount = amount * (1 + _min(target.maxHealth - source.maxHealth, 500) / 50 * (GetItemSlot(source, 3036) > 0 and 0.015 or 0.01))
            end
        end
    end
    return amount
end

local _EnemyHeroes
function GetEnemyHeroes()
    if _EnemyHeroes then return _EnemyHeroes end
    for i = 1, LocalGameHeroCount() do
        local unit = LocalGameHero(i)
        if unit.isEnemy then
	        if _EnemyHeroes == nil then _EnemyHeroes = {} end
        _insert(_EnemyHeroes, unit)
        end
    end
    return {}
end

local _OnVision = {}
function OnVision(unit)
    if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = LocalGetTickCount(), pos = unit.pos} end
	if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = LocalGetTickCount() end
	if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = LocalGetTickCount() end
	return _OnVision[unit.networkID]
end
Callback.Add("Tick", function() OnVisionF() end)
local visionTick = LocalGetTickCount()
function OnVisionF()
	if LocalGetTickCount() - visionTick > 100 then
		for i,v in _pairs(GetEnemyHeroes()) do
			OnVision(v)
		end
	end
end

function Priority(charName)
    local p1 = {"Alistar", "Amumu", "Blitzcrank", "Braum", "Cho'Gath", "Dr. Mundo", "Garen", "Gnar", "Maokai", "Hecarim", "Jarvan IV", "Leona", "Lulu", "Malphite", "Nasus", "Nautilus", "Nunu", "Olaf", "Rammus", "Renekton", "Sejuani", "Shen", "Shyvana", "Singed", "Sion", "Skarner", "Taric", "TahmKench", "Thresh", "Volibear", "Warwick", "MonkeyKing", "Yorick", "Zac", "Poppy"}
    local p2 = {"Aatrox", "Darius", "Elise", "Evelynn", "Galio", "Gragas", "Irelia", "Jax", "Lee Sin", "Morgana", "Janna", "Nocturne", "Pantheon", "Rengar", "Rumble", "Swain", "Trundle", "Tryndamere", "Udyr", "Urgot", "Vi", "XinZhao", "RekSai", "Bard", "Nami", "Sona", "Camille"}
    local p3 = {"Akali", "Diana", "Ekko", "FiddleSticks", "Fiora", "Gangplank", "Fizz", "Heimerdinger", "Jayce", "Kassadin", "Kayle", "Kha'Zix", "Lissandra", "Mordekaiser", "Nidalee", "Riven", "Shaco", "Vladimir", "Yasuo", "Zilean", "Zyra", "Ryze"}
    local p4 = {"Ahri", "Anivia", "Annie", "Ashe", "Azir", "Brand", "Caitlyn", "Cassiopeia", "Corki", "Draven", "Ezreal", "Graves", "Jinx", "Kalista", "Karma", "Karthus", "Katarina", "Kennen", "KogMaw", "Kindred", "Leblanc", "Lucian", "Lux", "Malzahar", "MasterYi", "MissFortune", "Orianna", "Quinn", "Sivir", "Syndra", "Talon", "Teemo", "Tristana", "TwistedFate", "Twitch", "Varus", "Vayne", "Veigar", "Velkoz", "Viktor", "Xerath", "Zed", "Ziggs", "Jhin", "Soraka"}
    if _contains(p1, charName) then return 1 end
    if _contains(p2, charName) then return 1.25 end
    if _contains(p3, charName) then return 1.75 end
    return _contains(p4, charName) and 2.25 or 1
end

function GetTarget(range,t,pos)
    local t = t or "AD"
    local pos = pos or myHero.pos
    local target = {}
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero.isEnemy and not hero.dead then
			OnVision(hero)
		end
		if hero.isEnemy and hero.valid and not hero.dead and (OnVision(hero).state == true or (OnVision(hero).state == false and LocalGetTickCount() - OnVision(hero).tick < 650)) and hero.isTargetable then
			local heroPos = hero.pos
			if OnVision(hero).state == false then heroPos = hero.pos + Vector(hero.pos,hero.posTo):Normalized() * ((LocalGetTickCount() - OnVision(hero).tick)/1000 * hero.ms) end
			if GetDistance(pos,heroPos) <= range then
				if t == "AD" then
					target[(CalcPhysicalDamage(myHero,hero,100) / hero.health) * Priority(hero.charName)] = hero
				elseif t == "AP" then
					target[(CalcMagicalDamage(myHero,hero,100) / hero.health) * Priority(hero.charName)] = hero
				elseif t == "HYB" then
					target[((CalcMagicalDamage(myHero,hero,50) + CalcPhysicalDamage(myHero,hero,50))/ hero.health) * Priority(hero.charName)] = hero
				end
			end
		end
	end
	local bT = 0
	for d,v in _pairs(target) do
		if d > bT then
			bT = d
		end
	end
	if bT ~= 0 then return target[bT] end
end

--[[class "Utility"

function Utility:__init()
	self.BC    = { id = 3144 }
	self.BOTRK = { id = 3153 }
	self.T     = { id = 3077 }
	self.RH    = { id = 3074 }
	self.TH    = { id = 3748 }
	self.HG    = { id = 3146 }
	self.GLP   = { id = 3030 }
	self.P01   = { id = 3152 }
	self.RO    = { id = 3143 }
	self.SB    = { id = 3907 }
	self.YG    = { id = 3142 }
	self.SR    = { id = 2056 }
	self.IS    = { id = 3190 }
	self.SE    = { id = 3040, ornnId = 3048 }
	self.GS    = { id = 3193 }
	self.HP    = { id = 2003 }
	self.CP    = { id = 2033 }
	self.RP    = { id = 2031 }
	self.HSP   = { id = 2032 }
	self.MP    = { id = 2004 }
	self.PHP   = { id = 2061 }
	self.TBEW  = { id = 2010 }
	self.RED   = { id = 3107, ornnId = 3382 }
	self.QSS   = { id = 3140 }
	self.MS    = { id = 3139 }
	self.MC    = { id = 3222 }
	self.Ignite  = { name = "SummonerDot" }
	self.Exhaust = { name = "SummonerExhaust" }
	self.Smite   = { blueName = "S5_SummonerSmitePlayerGanker", redName = "S5_SummonerSmiteDuel" }
	self.Barrier = { name = "SummonerBarrier" }
	self.Heal    = { name = "SummonerHeal" }
	self.Cleanse = { name = "SummonerBoost" }

	self:Config()
    function OnTick() self:Tick() end
    function OnDraw() self:Draw() end
end ]]


class "Brand"

function Brand:__init()
	self.Q = { range = 1050, delay = 0.25,  speed = 1600,  radius = 60,  checkCollision = true  }
    self.W = { range = 900,  delay = 0.625, speed = _huge, radius = 215, checkCollision = false }
    self.E = { range = 625 }
    self.R = { range = 750 }
    
    self:Config()
    function OnTick() self:Tick() end
    function OnDraw() self:Draw() end
end

function Brand:Config()
	Brand = MenuElement({id = "Brand", name = "InstaWin Brand", type = MENU})

    Brand:MenuElement({id = "combo", name = "Combo", type = MENU})
    Brand.combo:MenuElement({id = "useQ", name = "Q usage", value = true})
    Brand.combo:MenuElement({id = "ablazedQ", name = "Only if ablazed", value = true})
    Brand.combo:MenuElement({id = "skipQ", name = "Skip non-ablazed target [?]", value = true, tooltip = "If 'only if ablazed' is marked, it'll search for an ablazed target"})
    Brand.combo:MenuElement({id = "hitchanceQ", name = "Q hitchance", value = 2, drop = {"Ignore hitchance","Medium","High","Very high","Guaranted"}})
    Brand.combo:MenuElement({id = "useW", name = "W usage", value = true})
    Brand.combo:MenuElement({id = "hitchanceW", name = "W hitchance", value = 3, drop = {"Ignore hitchance","Medium","High","Very high","Guaranted"}})
    Brand.combo:MenuElement({id = "useE", name = "E usage", value = true})
    Brand.combo:MenuElement({id = "minionE", name = "Use ablazed minion to spread", value = true})

    Brand:MenuElement({id = "harass", name = "Harass", type = MENU})
    Brand.harass:MenuElement({id = "harassKey", name = "Key toggle", key = string.byte("N"), toggle = true})
    Brand.harass:MenuElement({id = "useQ", name = "Q usage", value = true})
    Brand.harass:MenuElement({id = "useQa", name = "Auto Q usage", value = false})
    Brand.harass:MenuElement({id = "ablazedQ", name = "Only if ablazed", value = true})
    Brand.harass:MenuElement({id = "skipQ", name = "Skip non-ablazed target [?]", value = true, tooltip = "If 'only if ablazed' is marked, it'll search for an ablazed target"})
    Brand.harass:MenuElement({id = "hitchanceQ", name = "Q hitchance", value = 2, drop = {"Ignore hitchance","Medium","High","Very high","Guaranted"}})
    Brand.harass:MenuElement({id = "useW", name = "W usage", value = true})
    Brand.harass:MenuElement({id = "useWa", name = "Auto W usage", value = true})
    Brand.harass:MenuElement({id = "hitchanceW", name = "W hitchance", value = 3, drop = {"Ignore hitchance","Medium","High","Very high","Guaranted"}})
    Brand.harass:MenuElement({id = "useE", name = "E usage", value = true})
    Brand.harass:MenuElement({id = "useEa", name = "Auto E usage", value = false})
    Brand.harass:MenuElement({id = "minionE", name = "Use ablazed minion to spread", value = true})
    Brand.harass:MenuElement({id = "whitelist", name = "Harass whitelist", type = MENU})
    GotEnemy = false
    for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
        if hero.isEnemy then
            if not GotEnemy then
                Brand.harass.whitelist:MenuElement({id = hero.charName, name = hero.charName, value = true})
            end
        end
    end

    Brand:MenuElement({id = "clear", name = "Clear", type = MENU})
    Brand.clear:MenuElement({id = "clearKey", name = "Key toggle", key = string.byte("N"), toggle = true})
    Brand.clear:MenuElement({id = "mana", name = "Clear mana", value = 50, min = 0, max = 100})
    Brand.clear:MenuElement({id = "laneW", name = "Laneclear W", value = true})
    Brand.clear:MenuElement({id = "laneE", name = "Laneclear E", value = true})
    Brand.clear:MenuElement({id = "laneX", name = "Laneclear minimun minions", value = 2, min = 0, max = 10})
    Brand.clear:MenuElement({id = "jungleQ", name = "Jungleclear Q", value = true})
    Brand.clear:MenuElement({id = "jungleW", name = "Jungleclear W", value = true})
    Brand.clear:MenuElement({id = "jungleE", name = "Jungleclear E", value = true})

    Brand:MenuElement({id = "misc", name = "Miscellaneous", type = MENU})
    Brand.misc:MenuElement({id = "killstealQ", name = "Q killsteal", value = true})
    Brand.misc:MenuElement({id = "hitchanceQ", name = "Q hitchance", value = 4, drop = {"Ignore hitchance","Medium","High","Very high","Guaranted"}})
    Brand.misc:MenuElement({id = "killstealW", name = "W killsteal", value = true})
    Brand.misc:MenuElement({id = "hitchanceW", name = "W hitchance", value = 3, drop = {"Ignore hitchance","Medium","High","Very high","Guaranted"}})
    Brand.misc:MenuElement({id = "killstealE", name = "E killsteal", value = true})
    Brand.misc:MenuElement({id = "interruptEQ", name = "E + Q interrupter", value = true})
    Brand.misc:MenuElement({id = "antigapcloseEQ", name = "E + Q antigapclose", value = true})
    Brand.misc:MenuElement({id = "multiR", name = "R multitarget", value = true})
    Brand.misc:MenuElement({id = "multiRx", name = "Enemy counter", value = 3, min = 1, max = 6})
    Brand.misc:MenuElement({id = "singleR", name = "Smart R duel logic", value = true})

    Brand:MenuElement({id = "draw", name = "Drawings", type = MENU})
    Brand.draw:MenuElement({id = "onlyReady", name = "Draw only ready spells", value = true})
    Brand.draw:MenuElement({id = "harassKey", name = "Draw harass toggle state", value = true})
    Brand.draw:MenuElement({id = "clearKey", name = "Draw clear toggle state", value = true})
    Brand.draw:MenuElement({id = "rangeQ", name = "Q range [?]", value = false, tooltip = "1050 units blue circle"})
	Brand.draw:MenuElement({id = "rangeW", name = "W range [?]", value = false, tooltip = "900 units green circle"})
	Brand.draw:MenuElement({id = "rangeE", name = "E range [?]", value = false, tooltip = "625 units yellow circle"})
    Brand.draw:MenuElement({id = "rangeR", name = "R range [?]", value = false, tooltip = "750 units red circle"})
end

function Brand:Draw()
    local heroPos2D = myHero.pos:To2D()
    if Brand.draw.harassKey:Value() then
		if Brand.harass.harassKey:Value() then
			Draw.Text("HARASS ON",  10, heroPos2D.x - 86, heroPos2D.y - -32, Draw.Color(150, 000, 255, 000)) 
		else
			Draw.Text("HARASS OFF", 10, heroPos2D.x - 86, heroPos2D.y - -32, Draw.Color(150, 000, 000, 000)) 
		end
	end
    if Brand.draw.clearKey:Value() then
		if Brand.clear.clearKey:Value() then
			Draw.Text("CLEAR ON",   10, heroPos2D.x + 7, heroPos2D.y - -32, Draw.Color(150, 000, 255, 000)) 
		else
			Draw.Text("CLEAR OFF",  10, heroPos2D.x + 7, heroPos2D.y - -32, Draw.Color(150, 000, 000, 000)) 
		end
    end
    if LocalMyHeroIsDead then return end
    local onlyReady = Brand.draw.onlyReady:Value()
    if onlyReady then
        if Brand.draw.rangeQ:Value() and LocalGameCanUseSpell(_Q) == 0 then LocalDrawCircle(myHero.pos, self.Q.range, 3, LocalDrawColor(040,000,000,255)) end
        if Brand.draw.rangeW:Value() and LocalGameCanUseSpell(_W) == 0 then LocalDrawCircle(myHero.pos, self.W.range, 3, LocalDrawColor(030,255,255,255)) end
        if Brand.draw.rangeE:Value() and LocalGameCanUseSpell(_E) == 0 then LocalDrawCircle(myHero.pos, self.E.range, 3, LocalDrawColor(040,255,153,204)) end
        if Brand.draw.rangeR:Value() and LocalGameCanUseSpell(_R) == 0 then LocalDrawCircle(myHero.pos, self.R.range, 3, LocalDrawColor(255,255,000,000)) end
    else
        if Brand.draw.rangeQ:Value() then LocalDrawCircle(myHero.pos, self.Q.range, 3, LocalDrawColor(255,000,000,255)) end
        if Brand.draw.rangeW:Value() then LocalDrawCircle(myHero.pos, self.W.range, 3, LocalDrawColor(255,000,255,000)) end
        if Brand.draw.rangeE:Value() then LocalDrawCircle(myHero.pos, self.E.range, 3, LocalDrawColor(255,255,255,000)) end
        if Brand.draw.rangeR:Value() then LocalDrawCircle(myHero.pos, self.R.range, 3, LocalDrawColor(255,255,000,000)) end
    end
end

function Brand:Tick()
	if LocalMyHeroIsDead then return end
	
	self:Miscellaneous()
	
	local mode =  GetMode()
    if mode == "Combo" then self:ComboLogic() end
	if mode == "Harass" then self:HarassLogic() end
	if mode == "Clear" then self:ClearLogic() end
end

function Brand:ManaManagement(spell)
	if LocalGameCanUseSpell(spell) == 0 then
		return myHero:GetSpellData(spell).mana
	else
		return 0
	end
end

function Brand:ComboLogic()
	local manaQ = self:ManaManagement(_Q)
	local manaW = self:ManaManagement(_W)
	local manaE = self:ManaManagement(_E)
	local manaR = self:ManaManagement(_R)

    local canCastQ                   = false
    local useQ                       = Brand.combo.useQ:Value()
    local ablazedQ                   = Brand.combo.ablazedQ:Value()
    local skipQ                      = Brand.combo.skipQ:Value()
    local hitchanceQ                 = Brand.combo.hitchanceQ:Value()
    local targetQ                    = GetTarget(self.Q.range, "AP")

    local useW                       = Brand.combo.useW:Value()
    local hitchanceW                 = Brand.combo.hitchanceW:Value()
    local targetW                    = GetTarget(self.W.range, "AP")

    local useE                       = Brand.combo.useE:Value()
    local minionE                    = Brand.combo.minionE:Value()
    local spreadRange                = 300
    local maxErange                  = self.E.range + spreadRange
    local targetE                    = GetTarget(maxErange, "AP")
    local spreadableMinion           = self:GetAblazedMinion(self.E.range)

    if targetQ and LocalGameCanUseSpell(_Q) == 0 and useQ and IsValidTarget(targetQ, self.Q.range) and myHero.mana > manaQ + manaR then
        canCastQ = true
        if not HasBuff(targetQ, "BrandAblaze") and ablazedQ then
            local secondaryTarget = self:GetAblazedEnemy(self.Q.range)
            if secondaryTarget and skipQ then
                targetQ = secondaryTarget
            else
                canCastQ = false
            end
        end
        if canCastQ then
            self:CastQ(targetQ, hitchanceQ)
        end
	end
	
	if targetE and LocalGameCanUseSpell(_E) == 0 and useE and IsValidTarget(targetE, maxErange) and myHero.mana > manaE + manaR then
        if IsValidTarget(targetE, self.E.range) then
            LocalControlCastSpell(HK_E, targetE)
        elseif minionE and spreadableMinion then
            if HeroesAround(spreadRange, spreadableMinion.pos, LocalEnemy) > 0 then
                LocalControlCastSpell(HK_E, spreadableMinion)
            end
        end
    end

    if targetW and LocalGameCanUseSpell(_W) == 0 and useW and IsValidTarget(targetW, self.W.range) and myHero.mana > manaW + manaR then
        self:CastW(targetW, hitchanceW)
    end
end

function Brand:HarassLogic()
    local toggle                     = Brand.harass.harassKey:Value()
    if not toggle then return end

    local manaQ = self:ManaManagement(_Q)
	local manaW = self:ManaManagement(_W)
	local manaE = self:ManaManagement(_E)
	local manaR = self:ManaManagement(_R)

    local canCastQ                   = false
    local useQ                       = Brand.harass.useQ:Value()
    local ablazedQ                   = Brand.harass.ablazedQ:Value()
    local skipQ                      = Brand.harass.skipQ:Value()
    local hitchanceQ                 = Brand.harass.hitchanceQ:Value()
    local targetQ                    = GetTarget(self.Q.range, "AP")

    local useW                       = Brand.harass.useW:Value()
    local hitchanceW                 = Brand.harass.hitchanceW:Value()
    local targetW                    = GetTarget(self.W.range, "AP")

    local useE                       = Brand.harass.useE:Value()
    local minionE                    = Brand.harass.minionE:Value()
    local spreadRange                = 300
    local maxErange                  = self.E.range + spreadRange
    local targetE                    = GetTarget(maxErange, "AP")
    local spreadableMinion           = self:GetAblazedMinion(self.E.range)


    if targetQ and LocalGameCanUseSpell(_Q) == 0 and useQ and IsValidTarget(targetQ, self.Q.range) and myHero.mana > manaQ + manaW + manaE + manaR then
        if Brand.harass.whitelist[targetQ.charName]:Value() then
            canCastQ = true
            if not HasBuff(targetQ, "BrandAblaze") and ablazedQ then
                local secondaryTarget = self:GetAblazedEnemy(self.Q.range)
                if secondaryTarget and Brand.harass.whitelist[secondaryTarget.charName]:Value() and skipQ then
                    targetQ = secondaryTarget
                else
                    canCastQ = false
                end
            end
            if canCastQ then
                self:CastQ(targetQ, hitchanceQ)
            end
        end
	end
	
	if targetE and LocalGameCanUseSpell(_E) == 0 and useE and IsValidTarget(targetE, maxErange) and myHero.mana > manaQ + manaW + manaE + manaR then
        if Brand.harass.whitelist[targetE.charName]:Value() then
            if IsValidTarget(targetE, self.E.range) then
                LocalControlCastSpell(HK_E, targetE)
            elseif minionE and spreadableMinion then
                if HeroesAround(spreadRange, spreadableMinion.pos, LocalEnemy) > 0 then
                    LocalControlCastSpell(HK_E, spreadableMinion)
                end
            end
        end
    end

    if targetW and LocalGameCanUseSpell(_W) == 0 and useW and IsValidTarget(targetW, self.W.range) and myHero.mana > manaQ + manaW + manaE + manaR then
        if Brand.harass.whitelist[targetW.charName]:Value() then
            self:CastW(targetW, hitchanceW)
        end
    end
end

function Brand:AutoHarassLogic()
    local toggle                     = Brand.harass.harassKey:Value()
    if not toggle then return end

    local manaQ = self:ManaManagement(_Q)
	local manaW = self:ManaManagement(_W)
	local manaE = self:ManaManagement(_E)
	local manaR = self:ManaManagement(_R)

    local canCastQ                   = false
    local useQ                       = Brand.harass.useQ:Value()
    local useQa                      = Brand.harass.useQa:Value()
    local ablazedQ                   = Brand.harass.ablazedQ:Value()
    local skipQ                      = Brand.harass.skipQ:Value()
    local hitchanceQ                 = Brand.harass.hitchanceQ:Value()
    local targetQ                    = GetTarget(self.Q.range, "AP")

    local useW                       = Brand.harass.useW:Value()
    local useWa                      = Brand.harass.useWa:Value()
    local hitchanceW                 = Brand.harass.hitchanceW:Value()
    local targetW                    = GetTarget(self.W.range, "AP")

    local useE                       = Brand.harass.useE:Value()
    local useEa                      = Brand.harass.useEa:Value()
    local minionE                    = Brand.harass.minionE:Value()
    local spreadRange                = 300
    local maxErange                  = self.E.range + spreadRange
    local targetE                    = GetTarget(maxErange, "AP")
    local spreadableMinion           = self:GetAblazedMinion(self.E.range)


    if targetQ and LocalGameCanUseSpell(_Q) == 0 and useQ and useQa and IsValidTarget(targetQ, self.Q.range) and myHero.mana > manaQ + manaW + manaE + manaR then
        if Brand.harass.whitelist[targetQ.charName]:Value() then
            canCastQ = true
            if not HasBuff(targetQ, "BrandAblaze") and ablazedQ then
                local secondaryTarget = self:GetAblazedEnemy(self.Q.range)
                if secondaryTarget and Brand.harass.whitelist[secondaryTarget.charName]:Value() and skipQ then
                    targetQ = secondaryTarget
                else
                    canCastQ = false
                end
            end
            if canCastQ then
                self:CastQ(targetQ, hitchanceQ)
            end
        end
	end
	
	if targetE and LocalGameCanUseSpell(_E) == 0 and useE and useEa and IsValidTarget(targetE, maxErange) and myHero.mana > manaQ + manaW + manaE + manaR then
        if Brand.harass.whitelist[targetE.charName]:Value() then
            if IsValidTarget(targetE, self.E.range) then
                LocalControlCastSpell(HK_E, targetE)
            elseif minionE and spreadableMinion then
                if HeroesAround(spreadRange, spreadableMinion.pos, LocalEnemy) > 0 then
                    LocalControlCastSpell(HK_E, spreadableMinion)
                end
            end
        end
    end

    if targetW and LocalGameCanUseSpell(_W) == 0 and useW and useWa and IsValidTarget(targetW, self.W.range) and myHero.mana > manaQ + manaW + manaE + manaR then
        if Brand.harass.whitelist[targetW.charName]:Value() then
            self:CastW(targetW, hitchanceW)
        end
    end
end

function Brand:ClearLogic()
    local enabled     = Brand.clear.clearKey:Value()
    local manamanager = Brand.clear.mana:Value()

    if enabled and GetPercentMP(myHero) >= manamanager then
        local laneW         = Brand.clear.laneW:Value()
        local laneE         = Brand.clear.laneE:Value()
        local minhit        = Brand.clear.laneX:Value()
        local jungleQ       = Brand.clear.jungleQ:Value()
        local jungleW       = Brand.clear.jungleW:Value()
        local jungleE       = Brand.clear.jungleW:Value()
        local ablazedminion = self:GetAblazedMinion(self.E.range)
        local jungleminion  = ClosestMinion(600, myHero.pos, LocalJungle)

        if LocalGameCanUseSpell(_E) == 0 and laneE then
            if ablazedminion then
                if MinionsAround(300, ablazedminion.pos, LocalEnemy) >= minhit then
                    LocalControlCastSpell(HK_E, ablazedminion)
                end
            end
        end
        if LocalGameCanUseSpell(_W) == 0 and laneW then
            local BestPos, BestHit = GetBestCircularFarmPos(self.W.range, self.W.radius)
            if BestPos and BestHit >= minhit then
                CastSpell(HK_W, BestPos, self.W.range)
            end
        end

        if LocalGameCanUseSpell(_E) == 0 and jungleE then
            if jungleminion then
                LocalControlCastSpell(HK_E, jungleminion, 600)
            end
        end
        if LocalGameCanUseSpell(_W) == 0 and jungleW then
            if jungleminion then
                self:CastW(jungleminion,1)
            end
        end
        if LocalGameCanUseSpell(_Q) == 0 and jungleQ then
            if jungleminion then
                self:CastQ(jungleminion,1)
            end
        end
    end
end

function Brand:CastQ(target, chance)
    if LocalGameCanUseSpell(_Q) == 0 then
        local hitChance, aimPosition = HPred:GetHitchance(myHero.pos, target, self.Q.range, self.Q.delay, self.Q.speed, self.Q.radius, true, nil)
        if hitChance and NewHitchance(myHero, target, self.Q.range, self.Q.delay, self.Q.speed, self.Q.radius, true) >= chance then
            CastSpell(HK_Q, aimPosition, self.Q.range)
        end
    end
end

function Brand:CastW(target, chance)
    if LocalGameCanUseSpell(_W) == 0 then
        local hitChance, aimPosition = HPred:GetHitchance(myHero.pos, target, self.W.range, self.W.delay, self.W.speed, self.W.radius, false, nil)
        if hitChance and NewHitchance(myHero, target, self.W.range, self.W.delay, self.W.speed, self.W.radius, false) >= chance then
            CastSpell(HK_W, aimPosition, self.W.range)
        end
    end
end

function Brand:LogicR()
    local bounceRange = 475
    local target = GetTarget(self.R.range + bounceRange, "AP")

    if target and IsValidTarget(target, self.R.range + bounceRange) then
        if Brand.misc.multiR:Value() and HeroesAround(bounceRange, target.pos, LocalEnemy) >= Brand.misc.multiRx:Value() and IsValidTarget(target, self.R.range) then
            LocalControlCastSpell(HK_R, target)
        end

        if Brand.misc.singleR:Value() then
            if HeroesAround(550, target.pos, LocalAlly) == 0 or GetPercentHP(myHero) < 50 or HeroesAround(bounceRange, target.pos, LocalEnemy) > 1 then
                
                local damageR = CalcMagicalDamage(myHero, target, ({100,200,300})[myHero:GetSpellData(_R).level] + (myHero.ap * 0.25))

                if target.health < damageR * 3 then
                    local totalDamage = damageR
                    local getMinions = MinionsAround(bounceRange, target.pos, LocalEnemy)

                    if IsValidTarget(target, self.R.range) then
                        if HeroesAround(bounceRange, target.pos, LocalEnemy) > 1 then
                            if getMinions and getMinions > 2 then
                                totalDamage = damageR * 2
                            else
                                totalDamage = damageR * 3
                            end
                        elseif getMinions and getMinions > 0 then
                            totalDamage = damageR * 2
                        end
                        if totalDamage > target.health then
                            LocalControlCastSpell(HK_R, target)
                        end
                    elseif target.health < damageR * 2 then
                        for i  = 1, LocalGameHeroCount(i) do
                            local Jumper = LocalGameHero(i)
                            if Jumper and Jumper.isEnemy and IsValidTarget(Jumper, self.R.range) then
                                if GetDistance(Jumper.pos,target.pos) < bounceRange then
                                    LocalControlCastSpell(HK_R, Jumper)
                                end
                            end
                        end
                        for i  = 1, LocalGameMinionCount(i) do
                            local Jumper = LocalGameMinion(i)
                            if Jumper and Jumper.isEnemy and IsValidTarget(Jumper, self.R.range) then
                                if GetDistance(Jumper.pos,target.pos) < bounceRange then
                                    LocalControlCastSpell(HK_R, Jumper)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function Brand:Miscellaneous()
	local manaQ = self:ManaManagement(_Q)
	local manaW = self:ManaManagement(_W)
	local manaE = self:ManaManagement(_E)
	local manaR = self:ManaManagement(_R)

	-- R
	if LocalGameCanUseSpell(_R) == 0 then
		self:LogicR()
	end

	-- Antigapclose
	for i  = 1, LocalGameHeroCount(i) do
        local Sender = LocalGameHero(i)
        if Sender and Sender.isEnemy then
            if Sender.pathing.hasMovePath and Sender.pathing.isDashing and Brand.misc.antigapcloseEQ:Value() and myHero.mana > manaQ + manaE then
                if IsValidTarget(Sender, self.E.range) and (LocalGameCanUseSpell(_E) == 0 or HasBuff(Sender, "BrandAblaze")) then
                    if LocalGameCanUseSpell(_E) == 0 then
                        LocalControlCastSpell(HK_E, Sender)
                    end
                    if LocalGameCanUseSpell(_Q) == 0 then
                        self:CastQ(Sender,2)
                    end
                end
            end
        end
    end

	-- Interrupter
	for i  = 1, LocalGameHeroCount(i) do
        local Sender = LocalGameHero(i)
        if Sender and Sender.isEnemy then
            if Sender.isChanneling and Brand.misc.interruptEQ:Value() and myHero.mana > manaQ + manaE then
                local hitChance, aimPosition = HPred:GetHitchance(myHero.pos, Sender, self.Q.range, self.Q.delay, self.Q.speed, self.Q.radius, self.Q.checkCollision)
                if hitChance and HitChance >= 2 then
                    if IsValidTarget(Sender, self.E.range) and (LocalGameCanUseSpell(_E) == 0 or HasBuff(Sender, "BrandAblaze")) then
                        if LocalGameCanUseSpell(_E) == 0 then
                            LocalControlCastSpell(HK_E, Sender)
                        end
                        if LocalGameCanUseSpell(_Q) == 0 then
                            self:CastQ(Sender,2)
                        end
                    end
                end
            end
        end
    end

	-- Killsteal
	local target = GetTarget(self.Q.range, "AP")
    if not target then return end
	
	if LocalGameCanUseSpell(_Q) == 0 and Brand.misc.killstealQ:Value() then
		local damageQ = CalcMagicalDamage(myHero, target, ({80,110,140,170,200})[myHero:GetSpellData(_Q).level] + (myHero.ap * 0.55))
		if damageQ > target.health then
			self:CastQ(target,Brand.misc.hitchanceQ:Value())
		end
	end
	if LocalGameCanUseSpell(_W) == 0 and Brand.misc.killstealW:Value() then
		local damageW = CalcMagicalDamage(myHero, target, ({75,120,165,210,255})[myHero:GetSpellData(_W).level] + (myHero.ap * 0.6))
		if damageW > target.health then
			self:CastW(target,Brand.misc.hitchanceW:Value())
		end
	end
	if LocalGameCanUseSpell(_E) == 0 and Brand.misc.killstealE:Value() then
		local damageE = CalcMagicalDamage(myHero, target, ({70,90,110,130,150})[myHero:GetSpellData(_E).level] + (myHero.ap * 0.35))
		if damageE > target.health then
			LocalControlCastSpell(HK_E, target)
		end
    end
end

function Brand:GetAblazedEnemy(range)
    local range = range or _huge
    for i  = 1, LocalGameHeroCount(i) do
        local Ablazed = LocalGameHero(i)
        if Ablazed and Ablazed.isEnemy then
            if IsValidTarget(Ablazed, range) and HasBuff(Ablazed, "BrandAblaze") then
                return Ablazed
            end
        end
    end
    return nil
end

function Brand:GetAblazedMinion(range)
    local range = range or _huge
    for i  = 1, LocalGameMinionCount(i) do
        local Ablazed = LocalGameMinion(i)
        if Ablazed and Ablazed.isEnemy then
            if IsValidTarget(Ablazed, range) and HasBuff(Ablazed, "BrandAblaze") then
                return Ablazed
            end
        end
    end
    return nil
end


class "HPred"
	
local _tickFrequency = .2
local _nextTick = LocalGameTimer()
local _reviveLookupTable = 
	{ 
		["LifeAura.troy"] = 4, 
		["ZileanBase_R_Buf.troy"] = 3,
		["Aatrox_Base_Passive_Death_Activate"] = 3
	}

local _blinkSpellLookupTable = 
	{ 
		["EzrealArcaneShift"] = 475, 
		["RiftWalk"] = 500,
		["EkkoEAttack"] = 0,
		["AlphaStrike"] = 0,
		["KatarinaE"] = -255,
		["KatarinaEDagger"] = { "Katarina_Base_Dagger_Ground_Indicator","Katarina_Skin01_Dagger_Ground_Indicator","Katarina_Skin02_Dagger_Ground_Indicator","Katarina_Skin03_Dagger_Ground_Indicator","Katarina_Skin04_Dagger_Ground_Indicator","Katarina_Skin05_Dagger_Ground_Indicator","Katarina_Skin06_Dagger_Ground_Indicator","Katarina_Skin07_Dagger_Ground_Indicator" ,"Katarina_Skin08_Dagger_Ground_Indicator","Katarina_Skin09_Dagger_Ground_Indicator"  }, 
	}

local _blinkLookupTable = 
	{ 
		"global_ss_flash_02.troy",
		"Lissandra_Base_E_Arrival.troy",
		"LeBlanc_Base_W_return_activation.troy"
	}

local _cachedBlinks = {}
local _cachedRevives = {}
local _cachedTeleports = {}
local _cachedMissiles = {}
local _incomingDamage = {}
local _windwall
local _windwallStartPos
local _windwallWidth

local _OnVision = {}
function HPred:OnVision(unit)
	if unit == nil or type(unit) ~= "userdata" then return end
	if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {visible = unit.visible , tick = LocalGetTickCount(), pos = unit.pos } end
	if _OnVision[unit.networkID].visible == true and not unit.visible then _OnVision[unit.networkID].visible = false _OnVision[unit.networkID].tick = LocalGetTickCount() end
	if _OnVision[unit.networkID].visible == false and unit.visible then _OnVision[unit.networkID].visible = true _OnVision[unit.networkID].tick = LocalGetTickCount() _OnVision[unit.networkID].pos = unit.pos end
	return _OnVision[unit.networkID]
end

function HPred:Tick()
	if _nextTick > LocalGameTimer() then return end
	_nextTick = LocalGameTimer() + _tickFrequency
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t then
			if t.isEnemy then
				HPred:OnVision(t)
			end
		end
	end
	if true then return end
	for _, teleport in _pairs(_cachedTeleports) do
		if teleport and LocalGameTimer() > teleport.expireTime + .5 then
			_cachedTeleports[_] = nil
		end
	end	
	HPred:CacheTeleports()
	HPred:CacheParticles()
	for _, revive in _pairs(_cachedRevives) do
		if LocalGameTimer() > revive.expireTime + .5 then
			_cachedRevives[_] = nil
		end
	end
	for _, revive in _pairs(_cachedRevives) do
		if LocalGameTimer() > revive.expireTime + .5 then
			_cachedRevives[_] = nil
		end
	end
	for i = 1, LocalGameParticleCount() do 
		local particle = LocalGameParticle(i)
		if particle and not _cachedRevives[particle.networkID] and  _reviveLookupTable[particle.name] then
			_cachedRevives[particle.networkID] = {}
			_cachedRevives[particle.networkID]["expireTime"] = LocalGameTimer() + _reviveLookupTable[particle.name]			
			local target = HPred:GetHeroByPosition(particle.pos)
			if target.isEnemy then				
				_cachedRevives[particle.networkID]["target"] = target
				_cachedRevives[particle.networkID]["pos"] = target.pos
				_cachedRevives[particle.networkID]["isEnemy"] = target.isEnemy	
			end
		end
		if particle and not _cachedBlinks[particle.networkID] and  _blinkLookupTable[particle.name] then
			_cachedBlinks[particle.networkID] = {}
			_cachedBlinks[particle.networkID]["expireTime"] = LocalGameTimer() + _reviveLookupTable[particle.name]			
			local target = HPred:GetHeroByPosition(particle.pos)
			if target.isEnemy then				
				_cachedBlinks[particle.networkID]["target"] = target
				_cachedBlinks[particle.networkID]["pos"] = target.pos
				_cachedBlinks[particle.networkID]["isEnemy"] = target.isEnemy	
			end
		end
	end
	
end

function HPred:GetEnemyNexusPosition()
	if myHero.team == 100 then return Vector(14340, 171.977722167969, 14390); else return Vector(396,182.132507324219,462); end
end


function HPred:GetGuarenteedTarget(source, range, delay, speed, radius, timingAccuracy, checkCollision)
	local target, aimPosition =self:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)	
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
end


function HPred:GetReliableTarget(source, range, delay, speed, radius, timingAccuracy, checkCollision)
	local target, aimPosition =self:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)	
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetInstantDashTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetDashingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius, midDash)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetBlinkTarget(source, range, speed, delay, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end	
end

function HPred:GetLineTargetCount(source, aimPos, delay, speed, width, targetAllies)
	local targetCount = 0
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t and self:CanTargetALL(t) and ( targetAllies or t.isEnemy) then
			local predictedPos = self:PredictUnitPosition(t, delay+ self:GetDistance(source, t.pos) / speed)
			local proj1, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(source, aimPos, predictedPos)
			if proj1 and isOnSegment and (self:GetDistanceSqr(predictedPos, proj1) <= (t.boundingRadius + width) * (t.boundingRadius + width)) then
				targetCount = targetCount + 1
			end
		end
	end
	return targetCount
end

function HPred:GetUnreliableTarget(source, range, delay, speed, radius, checkCollision, minimumHitChance, whitelist, isLine)
	local _validTargets = {}
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)		
		if t and self:CanTarget(t, true) and (not whitelist or whitelist[t.charName]) then
			local hitChance, aimPosition = self:GetHitchance(source, t, range, delay, speed, radius, checkCollision, isLine)		
			if hitChance >= minimumHitChance then
				_insert(_validTargets, {aimPosition,hitChance, hitChance * 100 + self:CalculateMagicDamage(t, 400)})
			end
		end
	end	
	_sort(_validTargets, function( a, b ) return a[3] >b[3] end)	
	if #_validTargets > 0 then	
		return _validTargets[1][2], _validTargets[1][1]
	end
end

function HPred:GetHitchance(source, target, range, delay, speed, radius, checkCollision, isLine)
	if isLine == nil and checkCollision then
		isLine = true
	end
	local hitChance = 1
	local aimPosition = self:PredictUnitPosition(target, delay + self:GetDistance(source, target.pos) / speed)	
	local interceptTime = self:GetSpellInterceptTime(source, aimPosition, delay, speed)
	local reactionTime = self:PredictReactionTime(target, .1, isLine)
	if isLine then
		local pathVector = aimPosition - target.pos
		local castVector = (aimPosition - myHero.pos):Normalized()
		if pathVector.x + pathVector.z ~= 0 then
			pathVector = pathVector:Normalized()
			if pathVector:DotProduct(castVector) < -.85 or pathVector:DotProduct(castVector) > .85 then
				if speed > 3000 then
					reactionTime = reactionTime + .25
				else
					reactionTime = reactionTime + .15
				end
			end
		end
	end
	Waypoints = self:GetCurrentWayPoints(target)
	if (#Waypoints == 1) then
		HitChance = 2
	end
	if self:isSlowed(target, delay, speed, source) then
		HitChance = 2
	end
	if self:GetDistance(source, target.pos) < 350 then
		HitChance = 2
	end
	local angletemp = Vector(source):AngleBetween(Vector(target.pos), Vector(aimPosition))
	if angletemp > 60 then
		HitChance = 1
	elseif angletemp < 10 then
		HitChance = 2
	end
	if not target.pathing or not target.pathing.hasMovePath then
		hitChancevisionData = 2
		hitChance = 2
	end
	local origin,movementRadius = self:UnitMovementBounds(target, interceptTime, reactionTime)
	if movementRadius - target.boundingRadius <= radius /2 then
		origin,movementRadius = self:UnitMovementBounds(target, interceptTime, 0)
		if movementRadius - target.boundingRadius <= radius /2 then
			hitChance = 4
		else		
			hitChance = 3
		end
	end	
	if target.activeSpell and target.activeSpell.valid then
		if target.activeSpell.startTime + target.activeSpell.windup - LocalGameTimer() >= delay then
			hitChance = 5
		else			
			hitChance = 3
		end
	end
	local visionData = HPred:OnVision(target)
	if visionData and visionData.visible == false then
		local hiddenTime = visionData.tick -LocalGetTickCount()
		if hiddenTime < -1000 then
			hitChance = -1
		else
			local targetSpeed = self:GetTargetMS(target)
			local unitPos = target.pos + Vector(target.pos,target.posTo):Normalized() * ((LocalGetTickCount() - visionData.tick)/1000 * targetSpeed)
			local aimPosition = unitPos + Vector(target.pos,target.posTo):Normalized() * (targetSpeed * (delay + (self:GetDistance(myHero.pos,unitPos)/speed)))
			if self:GetDistance(target.pos,aimPosition) > self:GetDistance(target.pos,target.posTo) then aimPosition = target.posTo end
			hitChance = _min(hitChance, 2)
		end
	end
	if not self:IsInRange(source, aimPosition, range) then
		hitChance = -1
	end
	if hitChance > 0 and checkCollision then
		if self:IsWindwallBlocking(source, aimPosition) then
			hitChance = -1		
		elseif self:CheckMinionCollision(source, aimPosition, delay, speed, radius) then
			hitChance = -1
		end
	end
	
	return hitChance, aimPosition
end

function HPred:PredictReactionTime(unit, minimumReactionTime)
    local reactionTime = minimumReactionTime
    if unit.activeSpell and unit.activeSpell.valid then
		local windupRemaining = unit.activeSpell.startTime + unit.activeSpell.windup - LocalGameTimer()
		if windupRemaining > 0 then
			reactionTime = windupRemaining
		end
	end	
	return reactionTime
end

function HPred:GetCurrentWayPoints(object)
	local result = {}
	if object.pathing.hasMovePath then
		_insert(result, Vector(object.pos.x,object.pos.y, object.pos.z))
		for i = object.pathing.pathIndex, object.pathing.pathCount do
			path = object:GetPath(i)
			_insert(result, Vector(path.x, path.y, path.z))
		end
	else
		_insert(result, object and Vector(object.pos.x,object.pos.y, object.pos.z) or Vector(object.pos.x,object.pos.y, object.pos.z))
	end
	return result
end

function HPred:GetDashingTarget(source, range, delay, speed, dashThreshold, checkCollision, radius, midDash)
	local target
	local aimPosition
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t and t.isEnemy and t.pathing.hasMovePath and t.pathing.isDashing and t.pathing.dashSpeed>500  then
			local dashEndPosition = t:GetPath(1)
			if self:IsInRange(source, dashEndPosition, range) then				
				local dashTimeRemaining = self:GetDistance(t.pos, dashEndPosition) / t.pathing.dashSpeed
				local skillInterceptTime = self:GetSpellInterceptTime(source, dashEndPosition, delay, speed)
				local deltaInterceptTime =skillInterceptTime - dashTimeRemaining
				if deltaInterceptTime > 0 and deltaInterceptTime < dashThreshold and (not checkCollision or not self:CheckMinionCollision(source, dashEndPosition, delay, speed, radius)) then
					target = t
					aimPosition = dashEndPosition
					return target, aimPosition
				end
			end			
		end
	end
end

function HPred:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t and t.isEnemy then		
			local success, timeRemaining = self:HasBuff(t, "zhonyasringshield")
			if success then
				local spellInterceptTime = self:GetSpellInterceptTime(source, t.pos, delay, speed)
				local deltaInterceptTime = spellInterceptTime - timeRemaining
				if spellInterceptTime > timeRemaining and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
					target = t
					aimPosition = t.pos
					return target, aimPosition
				end
			end
		end
	end
end

function HPred:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for _, revive in _pairs(_cachedRevives) do	
		if revive.isEnemy then
			local interceptTime = self:GetSpellInterceptTime(source, revive.pos, delay, speed)
			if interceptTime > revive.expireTime - LocalGameTimer() and interceptTime - revive.expireTime - LocalGameTimer() < timingAccuracy then
				target = revive.target
				aimPosition = revive.pos
				return target, aimPosition
			end
		end
	end	
end

function HPred:GetInstantDashTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t and t.isEnemy and t.activeSpell and t.activeSpell.valid and _blinkSpellLookupTable[t.activeSpell.name] then
			local windupRemaining = t.activeSpell.startTime + t.activeSpell.windup - LocalGameTimer()
			if windupRemaining > 0 then
				local endPos
				local blinkRange = _blinkSpellLookupTable[t.activeSpell.name]
				if type(blinkRange) == "table" then
				elseif blinkRange > 0 then
					endPos = Vector(t.activeSpell.placementPos.x, t.activeSpell.placementPos.y, t.activeSpell.placementPos.z)					
					endPos = t.activeSpell.startPos + (endPos- t.activeSpell.startPos):Normalized() * _min(self:GetDistance(t.activeSpell.startPos,endPos), range)
				else
					local blinkTarget = self:GetObjectByHandle(t.activeSpell.target)
					if blinkTarget then				
						local offsetDirection
						if blinkRange == 0 then				
							if t.activeSpell.name ==  "AlphaStrike" then
								windupRemaining = windupRemaining + .75
							end						
							offsetDirection = (blinkTarget.pos - t.pos):Normalized()
						elseif blinkRange == -1 then						
							offsetDirection = (t.pos-blinkTarget.pos):Normalized()
						elseif blinkRange == -255 then
							if radius > 250 then
								endPos = blinkTarget.pos
							end							
						end
						if offsetDirection then
							endPos = blinkTarget.pos - offsetDirection * blinkTarget.boundingRadius
						end
					end
				end
				local interceptTime = self:GetSpellInterceptTime(source, endPos, delay,speed)
				local deltaInterceptTime = interceptTime - windupRemaining
				if self:IsInRange(source, endPos, range) and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, endPos, delay, speed, radius)) then
					target = t
					aimPosition = endPos
					return target,aimPosition					
				end
			end
		end
	end
end

function HPred:GetBlinkTarget(source, range, speed, delay, checkCollision, radius)
	local target
	local aimPosition
	for _, particle in _pairs(_cachedBlinks) do
		if particle  and self:IsInRange(source, particle.pos, range) then
			local t = particle.target
			local pPos = particle.pos
			if t and t.isEnemy and (not checkCollision or not self:CheckMinionCollision(source, pPos, delay, speed, radius)) then
				target = t
				aimPosition = pPos
				return target,aimPosition
			end
		end		
	end
end

function HPred:GetChannelingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t then
			local interceptTime = self:GetSpellInterceptTime(source, t.pos, delay, speed)
			if self:CanTarget(t) and self:IsInRange(source, t.pos, range) and self:IsChannelling(t, interceptTime) and (not checkCollision or not self:CheckMinionCollision(source, t.pos, delay, speed, radius)) then
				target = t
				aimPosition = t.pos	
				return target, aimPosition
			end
		end
	end
end

function HPred:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t and self:CanTarget(t) and self:IsInRange(source, t.pos, range) then
			local immobileTime = self:GetImmobileTime(t)
			
			local interceptTime = self:GetSpellInterceptTime(source, t.pos, delay, speed)
			if immobileTime - interceptTime > timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, t.pos, delay, speed, radius)) then
				target = t
				aimPosition = t.pos
				return target, aimPosition
			end
		end
	end
end

function HPred:CacheTeleports()
	for i = 1, LocalGameTurretCount() do
		local turret = LocalGameTurret(i);
		if turret and turret.isEnemy and not _cachedTeleports[turret.networkID] then
			local hasBuff, expiresAt = self:HasBuff(turret, "teleport_target")
			if hasBuff then
				self:RecordTeleport(turret, self:GetTeleportOffset(turret.pos,223.31),expiresAt)
			end
		end
	end
	for i = 1, LocalGameWardCount() do
		local ward = LocalGameWard(i);
		if ward and ward.isEnemy and not _cachedTeleports[ward.networkID] then
			local hasBuff, expiresAt = self:HasBuff(ward, "teleport_target")
			if hasBuff then
				self:RecordTeleport(ward, self:GetTeleportOffset(ward.pos,100.01),expiresAt)
			end
		end
	end
	for i = 1, LocalGameMinionCount() do
		local minion = LocalGameMinion(i);
		if minion and minion.isEnemy and not _cachedTeleports[minion.networkID] then
			local hasBuff, expiresAt = self:HasBuff(minion, "teleport_target")
			if hasBuff then
				self:RecordTeleport(minion, self:GetTeleportOffset(minion.pos,143.25),expiresAt)
			end
		end
	end	
end

function HPred:RecordTeleport(target, aimPos, endTime)
	_cachedTeleports[target.networkID] = {}
	_cachedTeleports[target.networkID]["target"] = target
	_cachedTeleports[target.networkID]["aimPos"] = aimPos
	_cachedTeleports[target.networkID]["expireTime"] = endTime + LocalGameTimer()
end


function HPred:CalculateIncomingDamage()
	_incomingDamage = {}
	local currentTime = LocalGameTimer()
	for _, missile in _pairs(_cachedMissiles) do
		if missile then 
			local dist = self:GetDistance(missile.data.pos, missile.target.pos)			
			if missile.name == "" or currentTime >= missile.timeout or dist < missile.target.boundingRadius then
				_cachedMissiles[_] = nil
			else
				if not _incomingDamage[missile.target.networkID] then
					_incomingDamage[missile.target.networkID] = missile.damage
				else
					_incomingDamage[missile.target.networkID] = _incomingDamage[missile.target.networkID] + missile.damage
				end
			end
		end
	end	
end

function HPred:GetIncomingDamage(target)
	local damage = 0
	if _incomingDamage[target.networkID] then
		damage = _incomingDamage[target.networkID]
	end
	return damage
end

local _maxCacheRange = 3000
function HPred:CacheParticles()	
	if _windwall and _windwall.name == "" then
		_windwall = nil
	end
	
	for i = 1, LocalGameParticleCount() do
		local particle = LocalGameParticle(i)		
		if particle and self:IsInRange(particle.pos, myHero.pos, _maxCacheRange) then			
			if _find(particle.name, "W_windwall%d") and not _windwall then
				local owner =  self:GetObjectByHandle(particle.handle)
				if owner and owner.isEnemy then
					_windwall = particle
					_windwallStartPos = Vector(particle.pos.x, particle.pos.y, particle.pos.z)
					local index = _len(particle.name) - 5
					local spellLevel = _sub(particle.name, index, index) -1
					if type(spellLevel) ~= "number" then
						spellLevel = 1
					end
					_windwallWidth = 150 + spellLevel * 25					
				end
			end
		end
	end
end

function HPred:CacheMissiles()
	local currentTime = LocalGameTimer()
	for i = 1, LocalGameMissileCount() do
		local missile = LocalGameMissile(i)
		if missile and not _cachedMissiles[missile.networkID] and missile.missileData then
			if missile.missileData.target and missile.missileData.owner then
				local missileName = missile.missileData.name
				local owner =  self:GetObjectByHandle(missile.missileData.owner)	
				local target =  self:GetObjectByHandle(missile.missileData.target)		
				if owner and target and _find(target.type, "Hero") then
					if (_find(missileName, "BasicAttack") or _find(missileName, "CritAttack")) then
						_cachedMissiles[missile.networkID] = {}
						_cachedMissiles[missile.networkID].target = target
						_cachedMissiles[missile.networkID].data = missile
						_cachedMissiles[missile.networkID].danger = 1
						_cachedMissiles[missile.networkID].timeout = currentTime + 1.5
						local damage = owner.totalDamage
						if _find(missileName, "CritAttack") then
							damage = damage * 1.5
						end						
						_cachedMissiles[missile.networkID].damage = self:CalculatePhysicalDamage(target, damage)
					end
				end
			end
		end
	end
end

function HPred:CalculatePhysicalDamage(target, damage)			
	local targetArmor = target.armor * myHero.armorPenPercent - myHero.armorPen
	local damageReduction = 100 / ( 100 + targetArmor)
	if targetArmor < 0 then
		damageReduction = 2 - (100 / (100 - targetArmor))
	end		
	damage = damage * damageReduction	
	return damage
end

function HPred:CalculateMagicDamage(target, damage)			
	local targetMR = target.magicResist * myHero.magicPenPercent - myHero.magicPen
	local damageReduction = 100 / ( 100 + targetMR)
	if targetMR < 0 then
		damageReduction = 2 - (100 / (100 - targetMR))
	end		
	damage = damage * damageReduction
	return damage
end


function HPred:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for _, teleport in _pairs(_cachedTeleports) do
		if teleport.expireTime > LocalGameTimer() and self:IsInRange(source,teleport.aimPos, range) then			
			local spellInterceptTime = self:GetSpellInterceptTime(source, teleport.aimPos, delay, speed)
			local teleportRemaining = teleport.expireTime - LocalGameTimer()
			if spellInterceptTime > teleportRemaining and spellInterceptTime - teleportRemaining <= timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, teleport.aimPos, delay, speed, radius)) then								
				target = teleport.target
				aimPosition = teleport.aimPos
				return target, aimPosition
			end
		end
	end		
end

function HPred:GetTargetMS(target)
	local ms = target.pathing.isDashing and target.pathing.dashSpeed or target.ms
	return ms
end

function HPred:Angle(A, B)
	local deltaPos = A - B
	local angle = _atan(deltaPos.x, deltaPos.z) *  180 / _pi	
	if angle < 0 then angle = angle + 360 end
	return angle
end

function HPred:PredictUnitPosition(unit, delay)
	local predictedPosition = unit.pos
	local timeRemaining = delay
	local pathNodes = self:GetPathNodes(unit)
	for i = 1, #pathNodes -1 do
		local nodeDistance = self:GetDistance(pathNodes[i], pathNodes[i +1])
		local nodeTraversalTime = nodeDistance / self:GetTargetMS(unit)
		if timeRemaining > nodeTraversalTime then
			timeRemaining =  timeRemaining - nodeTraversalTime
			predictedPosition = pathNodes[i + 1]
		else
			local directionVector = (pathNodes[i+1] - pathNodes[i]):Normalized()
			predictedPosition = pathNodes[i] + directionVector *  self:GetTargetMS(unit) * timeRemaining
			break;
		end
	end
	return predictedPosition
end

function HPred:IsChannelling(target, interceptTime)
	if target.activeSpell and target.activeSpell.valid and target.activeSpell.isChanneling then
		return true
	end
end

function HPred:HasBuff(target, buffName, minimumDuration)
	local duration = minimumDuration
	if not minimumDuration then
		duration = 0
	end
	local durationRemaining
	for i = 1, target.buffCount do 
		local buff = target:GetBuff(i)
		if buff.duration > duration and buff.name == buffName then
			durationRemaining = buff.duration
			return true, durationRemaining
		end
	end
end

function HPred:GetTeleportOffset(origin, magnitude)
	local teleportOffset = origin + (self:GetEnemyNexusPosition()- origin):Normalized() * magnitude
	return teleportOffset
end

function HPred:GetSpellInterceptTime(startPos, endPos, delay, speed)	
	local interceptTime = Game.Latency()/2000 + delay + self:GetDistance(startPos, endPos) / speed
	return interceptTime
end

function HPred:CanTarget(target, allowInvisible)
	return target.isEnemy and target.alive and target.health > 0  and (allowInvisible or target.visible) and target.isTargetable
end

function HPred:CanTargetALL(target)
	return target.alive and target.health > 0 and target.visible and target.isTargetable
end

function HPred:UnitMovementBounds(unit, delay, reactionTime)
	local startPosition = self:PredictUnitPosition(unit, delay)
	local radius = 0
	local deltaDelay = delay -reactionTime- self:GetImmobileTime(unit)	
	if (deltaDelay >0) then
		radius = self:GetTargetMS(unit) * deltaDelay	
	end
	return startPosition, radius	
end

function HPred:GetImmobileTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration> duration and (buff.type == 5 or buff.type == 8 or buff.type == 21 or buff.type == 22 or buff.type == 24 or buff.type == 11 or buff.type == 29 or buff.type == 30 or buff.type == 39 ) then
			duration = buff.duration
		end
	end
	return duration		
end

function HPred:isSlowed(unit, delay, speed, from)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if from and unit and buff.count > 0 and buff.duration>=(delay + GetDistance(unit.pos, from) / speed) then
			if (buff.type == 10) then
				return true
			end
		end
	end
	return false
end

function HPred:GetSlowedTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration > duration and buff.type == 10 then
			duration = buff.duration			
			return duration
		end
	end
	return duration		
end

function HPred:GetPathNodes(unit)
	local nodes = {}
	_insert(nodes, unit.pos)
	if unit.pathing.hasMovePath then
		for i = unit.pathing.pathIndex, unit.pathing.pathCount do
			path = unit:GetPath(i)
			_insert(nodes, path)
		end
	end		
	return nodes
end

function HPred:GetObjectByHandle(handle)
	local target
	for i = 1, LocalGameHeroCount() do
		local enemy = LocalGameHero(i)
		if enemy and enemy.handle == handle then
			target = enemy
			return target
		end
	end
	for i = 1, LocalGameMinionCount() do
		local minion = LocalGameMinion(i)
		if minion and minion.handle == handle then
			target = minion
			return target
		end
	end
	for i = 1, LocalGameWardCount() do
		local ward = LocalGameWard(i);
		if ward and ward.handle == handle then
			target = ward
			return target
		end
	end
	for i = 1, LocalGameTurretCount() do 
		local turret = LocalGameTurret(i)
		if turret and turret.handle == handle then
			target = turret
			return target
		end
	end
	for i = 1, LocalGameParticleCount() do 
		local particle = LocalGameParticle(i)
		if particle and particle.handle == handle then
			target = particle
			return target
		end
	end
end

function HPred:GetHeroByPosition(position)
	local target
	for i = 1, LocalGameHeroCount() do
		local enemy = LocalGameHero(i)
		if enemy and enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
end

function HPred:GetObjectByPosition(position)
	local target
	for i = 1, LocalGameHeroCount() do
		local enemy = LocalGameHero(i)
		if enemy and enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	for i = 1, LocalGameMinionCount() do
		local enemy = LocalGameMinion(i)
		if enemy and enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	for i = 1, LocalGameWardCount() do
		local enemy = LocalGameWard(i);
		if enemy and enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	for i = 1, LocalGameParticleCount() do 
		local enemy = LocalGameParticle(i)
		if enemy and enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
end

function HPred:GetEnemyHeroByHandle(handle)	
	local target
	for i = 1, LocalGameHeroCount() do
		local enemy = LocalGameHero(i)
		if enemy and enemy.handle == handle then
			target = enemy
			return target
		end
	end
end

function HPred:GetNearestParticleByNames(origin, names)
	local target
	local distance = 999999
	for i = 1, LocalGameParticleCount() do 
		local particle = LocalGameParticle(i)
		if particle then 
			local d = self:GetDistance(origin, particle.pos)
			if d < distance then
				distance = d
				target = particle
			end
		end
	end
	return target, distance
end

function HPred:GetPathLength(nodes)
	local result = 0
	for i = 1, #nodes -1 do
		result = result + self:GetDistance(nodes[i], nodes[i + 1])
	end
	return result
end

function HPred:CheckMinionCollision(origin, endPos, delay, speed, radius, frequency)
	if not frequency then
		frequency = radius
	end
	local directionVector = (endPos - origin):Normalized()
	local checkCount = self:GetDistance(origin, endPos) / frequency
	for i = 1, checkCount do
		local checkPosition = origin + directionVector * i * frequency
		local checkDelay = delay + self:GetDistance(origin, checkPosition) / speed
		if self:IsMinionIntersection(checkPosition, radius, checkDelay, radius * 3) then
			return true
		end
	end
	return false
end

function HPred:IsMinionIntersection(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 500
	end
	for i = 1, LocalGameMinionCount() do
		local minion = LocalGameMinion(i)
		if minion and self:CanTarget(minion) and self:IsInRange(minion.pos, location, maxDistance) then
			local predictedPosition = self:PredictUnitPosition(minion, delay)
			if self:IsInRange(location, predictedPosition, radius + minion.boundingRadius) then
				return true
			end
		end
	end
	return false
end

function HPred:VectorPointProjectionOnLineSegment(v1, v2, v)
	assert(v1 and v2 and v, "VectorPointProjectionOnLineSegment: wrong argument types (3 <Vector> expected)")
	local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
	local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	local isOnSegment = rS == rL
	local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
	return pointSegment, pointLine, isOnSegment
end

function HPred:IsWindwallBlocking(source, target)
	if _windwall then
		local windwallFacing = (_windwallStartPos-_windwall.pos):Normalized()
		return self:DoLineSegmentsIntersect(source, target, _windwall.pos + windwallFacing:Perpendicular() * _windwallWidth, _windwall.pos + windwallFacing:Perpendicular2() * _windwallWidth)
	end	
	return false
end

function HPred:DoLineSegmentsIntersect(A, B, C, D)
	local o1 = self:GetOrientation(A, B, C)
	local o2 = self:GetOrientation(A, B, D)
	local o3 = self:GetOrientation(C, D, A)
	local o4 = self:GetOrientation(C, D, B)
	if o1 ~= o2 and o3 ~= o4 then
		return true
	end
	if o1 == 0 and self:IsOnSegment(A, C, B) then return true end
	if o2 == 0 and self:IsOnSegment(A, D, B) then return true end
	if o3 == 0 and self:IsOnSegment(C, A, D) then return true end
	if o4 == 0 and self:IsOnSegment(C, B, D) then return true end
	
	return false
end

function HPred:GetOrientation(A,B,C)
	local val = (B.z - A.z) * (C.x - B.x) -
		(B.x - A.x) * (C.z - B.z)
	if val == 0 then
		return 0
	elseif val > 0 then
		return 1
	else
		return 2
	end
	
end

function HPred:IsOnSegment(A, B, C)
	return B.x <= _max(A.x, C.x) and 
		B.x >= _min(A.x, C.x) and
		B.z <= _max(A.z, C.z) and
		B.z >= _min(A.z, C.z)
end

function HPred:GetSlope(A, B)
	return (B.z - A.z) / (B.x - A.x)
end

function HPred:GetEnemyByName(name)
	local target
	for i = 1, LocalGameHeroCount() do
		local enemy = LocalGameHero(i)
		if enemy and enemy.isEnemy and enemy.charName == name then
			target = enemy
			return target
		end
	end
end

function HPred:IsPointInArc(source, origin, target, angle, range)
	local deltaAngle = _abs(HPred:Angle(origin, target) - HPred:Angle(source, origin))
	if deltaAngle < angle and self:IsInRange(origin,target,range) then
		return true
	end
end

function HPred:GetDistanceSqr(p1, p2)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined GetDistanceSqr target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return _huge
	end
	return (p1.x - p2.x) *  (p1.x - p2.x) + ((p1.z or p1.y) - (p2.z or p2.y)) * ((p1.z or p1.y) - (p2.z or p2.y)) 
end

function HPred:IsInRange(p1, p2, range)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined IsInRange target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return false
	end
	return (p1.x - p2.x) *  (p1.x - p2.x) + ((p1.z or p1.y) - (p2.z or p2.y)) * ((p1.z or p1.y) - (p2.z or p2.y)) < range * range 
end

function HPred:GetDistance(p1, p2)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		_print("Undefined GetDistance target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return _huge
	end
	return _sqrt(self:GetDistanceSqr(p1, p2))
end
