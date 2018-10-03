local CAMenu = MenuElement({type = MENU, id = "CAMenu", name = "Champion Tracker", leftIcon = "http://puu.sh/rGodn/41bac3be46.png"})
CAMenu:MenuElement({id = "Enabled", name = "Enabled", value = true})
CAMenu:MenuElement({type = MENU, id = "SpellTracker", name = "Spell Tracker", leftIcon = "http://puu.sh/rGqMW/ae5ae40702.png"})
CAMenu.SpellTracker:MenuElement({id = "Enabled", name = "Enabled", value = true})
CAMenu.SpellTracker:MenuElement({id = "TEnemies", name = "Track Enemies", value = true, leftIcon = "http://puu.sh/rGoYt/5c99e94d8a.png"})
CAMenu.SpellTracker:MenuElement({id = "TAllies", name = "Track Allies", value = true, leftIcon = "http://puu.sh/rGoYo/0e0e445743.png"})
CAMenu.SpellTracker:MenuElement({id = "TrackTrinket", name = "Track Trinket", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.12.1/img/item/3340.png"})
CAMenu:MenuElement({type = MENU, id = "ExpTracker", name = "Experience Tracker", leftIcon = "http://puu.sh/rGqYg/1fdc5f1edb.png"})
CAMenu.ExpTracker:MenuElement({id = "Enabled", name = "Enabled", value = true})
CAMenu.ExpTracker:MenuElement({id = "TEnemies", name = "Track Enemies", value = true, leftIcon = "http://puu.sh/rGoYt/5c99e94d8a.png"})
CAMenu.ExpTracker:MenuElement({id = "TAllies", name = "Track Allies", value = true, leftIcon = "http://puu.sh/rGoYo/0e0e445743.png"})
CAMenu:MenuElement({type = MENU, id = "WaypointTracker", name = "Waypoint Tracker", leftIcon = "http://puu.sh/rGrat/917b634930.png"})
CAMenu.WaypointTracker:MenuElement({id = "Enabled", name = "Enabled", value = true})
CAMenu.WaypointTracker:MenuElement({id = "TEnemies", name = "Track Enemies", value = true, leftIcon = "http://puu.sh/rGoYt/5c99e94d8a.png"})
CAMenu.WaypointTracker:MenuElement({id = "TAllies", name = "Track Allies", value = true, leftIcon = "http://puu.sh/rGoYo/0e0e445743.png"})
CAMenu.WaypointTracker:MenuElement({id = "EPName", name = "Show Name", value = true})
CAMenu.WaypointTracker:MenuElement({id = "EPTime", name = "Show Time", value = true})

local mapID = Game.mapID;
ExpGain = {0,280,660,1140,1720,2400,3180,4060,5040,6120,7300,8580,9960,11440,13020,14700,16480,18360}; --summonersift, feel free for treeline or abyss


local summonerSprites = {};
local XposX = 90;
local YposY = 0;

summonerSprites[1] = { Sprite("SpellTracker\\1.png"), "SummonerBarrier" }
summonerSprites[2] = { Sprite("SpellTracker\\2.png"), "SummonerBoost" }
summonerSprites[3] = { Sprite("SpellTracker\\3.png"), "SummonerDot" }
summonerSprites[4] = { Sprite("SpellTracker\\4.png"), "SummonerExhaust" }
summonerSprites[5] = { Sprite("SpellTracker\\5.png"), "SummonerFlash" }
summonerSprites[6] = { Sprite("SpellTracker\\6.png"), "SummonerHaste" }
summonerSprites[7] = { Sprite("SpellTracker\\7.png"), "SummonerHeal" }
summonerSprites[8] = { Sprite("SpellTracker\\8.png"), "SummonerSmite" }
summonerSprites[9] = { Sprite("SpellTracker\\9.png"), "SummonerTeleport" }
summonerSprites[10] = { Sprite("SpellTracker\\10.png"), "S5_SummonerSmiteDuel" }
summonerSprites[11] = { Sprite("SpellTracker\\11.png"), "S5_SummonerSmitePlayerGanker" }
summonerSprites[12] = { Sprite("SpellTracker\\12.png"), "SummonerPoroRecall" }
summonerSprites[13] = { Sprite("SpellTracker\\13.png"), "SummonerPoroThrow" }


local function GetSpriteByName(name)
for i, summonerSprite in pairs(summonerSprites) do
	if summonerSprite[2] == name then
		return summonerSprite[1];
		end
	end
end


local function DrawSpellTracking(type, hero)
if not CAMenu.SpellTracker[type] then
		return
	end
if not CAMenu.SpellTracker[type]:Value() then
		return
	end
if hero.pos2D.onScreen then
	Draw.Rect(hero.pos2D.x-XposX-5-1,hero.pos2D.y+YposY+3+12-1, 118+2 , 12+2 ,Draw.Color(0x7A000000)); --whole bar
	
	Draw.Rect(hero.pos2D.x-XposX+3+27*0,hero.pos2D.y+YposY+3+16,23,4,Draw.Color(0xAA000000));  --spell bars
	Draw.Rect(hero.pos2D.x-XposX+3+27*1,hero.pos2D.y+YposY+3+16,23,4,Draw.Color(0xAA000000));
	Draw.Rect(hero.pos2D.x-XposX+3+27*2,hero.pos2D.y+YposY+3+16,23,4,Draw.Color(0xAA000000));
	Draw.Rect(hero.pos2D.x-XposX+3+27*3,hero.pos2D.y+YposY+3+16,23,4,Draw.Color(0xAA000000));
	
	Draw.Rect(hero.pos2D.x-XposX-5+121-1,hero.pos2D.y+YposY+3+12-1, 33+2 , 12+2 ,Draw.Color(0x7A00005A)); --whole bar
	Draw.Rect(hero.pos2D.x-XposX+121,hero.pos2D.y+YposY+3+16,23,4,Draw.Color(0xAA000000));  --spell bars
	local QData = hero:GetSpellData(_Q);
	if QData.level > 0 then
		for z = 1, QData.level do
			Draw.Rect(hero.pos2D.x-XposX+27*0+z*5-1,hero.pos2D.y+YposY+3+21, 1 , 2 ,Draw.Color(0xFFf2da65));
			end
		if QData.ammoCurrentCd > 0 then
			if QData.ammo > 0 then
				Draw.Rect(hero.pos2D.x-XposX+3+27*0,hero.pos2D.y+YposY+3+16, 23 - ((QData.ammoCurrentCd / QData.ammoCd) * 23) ,4,Draw.Color(0xFF983af3));
				else
				Draw.Rect(hero.pos2D.x-XposX+3+27*0,hero.pos2D.y+YposY+3+16, 23 - ((QData.ammoCurrentCd / QData.ammoCd) * 23) ,4,Draw.Color(0xf2e80d0d));
				end
			else
			if QData.currentCd > 0 then
				Draw.Rect(hero.pos2D.x-XposX+3+27*0,hero.pos2D.y+YposY+3+16, 23 - ((QData.currentCd / QData.cd) * 23) ,4,Draw.Color(0xf2e80d0d));
				else
				Draw.Rect(hero.pos2D.x-XposX+3+27*0,hero.pos2D.y+YposY+3+16,23,4,Draw.Color(0xFF42aade));
				end;
			end
		end
	local WData = hero:GetSpellData(_W);
	if WData.level > 0 then
		for  z = 1, WData.level do
			Draw.Rect(hero.pos2D.x-XposX+27*1+z*5-1,hero.pos2D.y+YposY+3+21, 1 , 2 ,Draw.Color(0xFFf2da65));
			end
		if WData.ammoCurrentCd > 0 then
			if WData.ammo > 0 then
				Draw.Rect(hero.pos2D.x-XposX+3+27*1,hero.pos2D.y+YposY+3+16, 23 - ((WData.ammoCurrentCd / WData.ammoCd) * 23) ,4,Draw.Color(0xFF983af3));
				else
				Draw.Rect(hero.pos2D.x-XposX+3+27*1,hero.pos2D.y+YposY+3+16, 23 - ((WData.ammoCurrentCd / WData.ammoCd) * 23) ,4,Draw.Color(0xf2e80d0d));
				end
			else
			if WData.currentCd > 0 then
				Draw.Rect(hero.pos2D.x-XposX+3+27*1,hero.pos2D.y+YposY+3+16, 23 - ((WData.currentCd / WData.cd) * 23) ,4,Draw.Color(0xf2e80d0d));
				else
				Draw.Rect(hero.pos2D.x-XposX+3+27*1,hero.pos2D.y+YposY+3+16,23,4,Draw.Color(0xFF42aade));
				end;
			end;
		end
	local EData = hero:GetSpellData(_E);
	if EData.level > 0 then
		for  z = 1, EData.level do
			Draw.Rect(hero.pos2D.x-XposX+27*2+z*5-1,hero.pos2D.y+YposY+3+21, 1 , 2 ,Draw.Color(0xFFf2da65));
			end
		if EData.ammoCurrentCd > 0 then
			if EData.ammo > 0 then
				Draw.Rect(hero.pos2D.x-XposX+3+27*2,hero.pos2D.y+YposY+3+16, 23 - ((EData.ammoCurrentCd / EData.ammoCd) * 23) ,4,Draw.Color(0xFF983af3));
				else
				Draw.Rect(hero.pos2D.x-XposX+3+27*2,hero.pos2D.y+YposY+3+16, 23 - ((EData.ammoCurrentCd / EData.ammoCd) * 23) ,4,Draw.Color(0xf2e80d0d));
				end
			else
			if EData.currentCd > 0 then
				Draw.Rect(hero.pos2D.x-XposX+3+27*2,hero.pos2D.y+YposY+3+16, 23 - ((EData.currentCd / EData.cd) * 23) ,4,Draw.Color(0xf2e80d0d));
				else
				Draw.Rect(hero.pos2D.x-XposX+3+27*2,hero.pos2D.y+YposY+3+16,23,4,Draw.Color(0xFF42aade));
				end;
			end;
		end
	local RData = hero:GetSpellData(_R);
	if RData.level > 0 then
		for  z = 1, RData.level do
			Draw.Rect(hero.pos2D.x-XposX+27*3+z*5-1,hero.pos2D.y+YposY+3+21, 1 , 2 ,Draw.Color(0xFFf2da65));
			end
		if RData.ammoCurrentCd > 0 then
			if RData.ammo > 0 then
				Draw.Rect(hero.pos2D.x-XposX+3+27*3,hero.pos2D.y+YposY+3+16, 23 - ((RData.ammoCurrentCd / RData.ammoCd) * 23) ,4,Draw.Color(0xFF983af3));
				else
				Draw.Rect(hero.pos2D.x-XposX+3+27*3,hero.pos2D.y+YposY+3+16, 23 - ((RData.ammoCurrentCd / RData.ammoCd) * 23) ,4,Draw.Color(0xf2e80d0d));
				end
			else
			if RData.currentCd > 0 then
				Draw.Rect(hero.pos2D.x-XposX+3+27*3,hero.pos2D.y+YposY+3+16, 23 - ((RData.currentCd / RData.cd) * 23) ,4,Draw.Color(0xf2e80d0d));
				else
				Draw.Rect(hero.pos2D.x-XposX+3+27*3,hero.pos2D.y+YposY+3+16,23,4,Draw.Color(0xFF42aade));
				end;
			end;
		end
	local TData = hero:GetSpellData(ITEM_7);
	if TData.level > 0 then
		if TData.ammoCurrentCd > 0 then
			if TData.ammo > 0 then
				Draw.Rect(hero.pos2D.x-XposX+121,hero.pos2D.y+YposY+3+16, 23 - ((TData.ammoCurrentCd / TData.ammoCd) * 23) ,4,Draw.Color(0xFF983af3));
				else
				Draw.Rect(hero.pos2D.x-XposX+121,hero.pos2D.y+YposY+3+16, 23 - ((TData.ammoCurrentCd / TData.ammoCd) * 23) ,4,Draw.Color(0xf2e80d0d));
				end
			else
			if TData.currentCd > 0 then
				Draw.Rect(hero.pos2D.x-XposX+121,hero.pos2D.y+YposY+3+16, 23 - ((TData.currentCd / TData.cd) * 23) ,4,Draw.Color(0xf2e80d0d));
				else
				Draw.Rect(hero.pos2D.x-XposX+121,hero.pos2D.y+YposY+3+16,23,4,Draw.Color(0xFF42aade));
				end;
			end;
		end
	local DData = hero:GetSpellData(SUMMONER_1);
	if DData.level > 0 then
	local SpellYOffset = 0;
		if DData.ammoCurrentCd > 0 then
			if DData.ammo > 0 then
				Draw.Rect(hero.pos2D.x-XposX+120+33-1, hero.pos2D.y+YposY+3+12-1,14,14,Draw.Color(0xFF983af3));
				else
				Draw.Rect(hero.pos2D.x-XposX+120+33-1, hero.pos2D.y+YposY+3+12-1,14,14,Draw.Color(0xf2e80d0d));
				end
			SpellYOffset = math.max(  (228 -  math.ceil((DData.ammoCurrentCd / DData.ammoCd) * 20) * 12)  ,0);
			else
			if DData.currentCd > 0 then
				Draw.Rect(hero.pos2D.x-XposX+120+33-1, hero.pos2D.y+YposY+3+12-1,14,14,Draw.Color(0xf2e80d0d));
				SpellYOffset = math.max(  (228 -  math.ceil((DData.currentCd / DData.cd) * 20) * 12)  ,0);
				else
				Draw.Rect(hero.pos2D.x-XposX+120+33-1, hero.pos2D.y+YposY+3+12-1,14,14,Draw.Color(0xFFb2ed5a));
				SpellYOffset = 228;
				end;
			end;
		local SprIdx1 = GetSpriteByName(DData.name);
		if SprIdx1 ~= nil then
			local sprCut = {x = 0, y = SpellYOffset, w = 12, h = SpellYOffset+12}
			SprIdx1:Draw(sprCut, hero.pos2D.x-XposX+120+33, hero.pos2D.y+YposY+3+12);
			end
		end
	local FData = hero:GetSpellData(SUMMONER_2);
	if FData.level > 0 then
	local SpellYOffset = 0;
		if FData.ammoCurrentCd > 0 then
			if FData.ammo > 0 then
				Draw.Rect(hero.pos2D.x-XposX+120+33-1+16, hero.pos2D.y+YposY+3+12-1,14,14,Draw.Color(0xFF983af3));
				else
				Draw.Rect(hero.pos2D.x-XposX+120+33-1+16, hero.pos2D.y+YposY+3+12-1,14,14,Draw.Color(0xf2e80d0d));
				end
			SpellYOffset = math.max(  (228 -  math.ceil((FData.ammoCurrentCd / FData.ammoCd) * 20) * 12)  ,0);
			else
			if FData.currentCd > 0 then
				Draw.Rect(hero.pos2D.x-XposX+120+33-1+16, hero.pos2D.y+YposY+3+12-1,14,14,Draw.Color(0xf2e80d0d));
				SpellYOffset = math.max(  (228 -  math.ceil((FData.currentCd / FData.cd) * 20) * 12)  ,0);
				else
				Draw.Rect(hero.pos2D.x-XposX+120+33-1+16, hero.pos2D.y+YposY+3+12-1,14,14,Draw.Color(0xFFb2ed5a));
				SpellYOffset = 228;
				end;
			end;
		local SprIdx2 = GetSpriteByName(FData.name);
		if SprIdx2 ~= nil then
			local sprCut = {x = 0, y = SpellYOffset, w = 12, h = SpellYOffset+12}
			--DrawSprite(SprIdx2, hero.pos2D.x-XposX+120+33+16, hero.pos2D.y+YposY+3+12, 0, SpellYOffset, 12, SpellYOffset+12, 0xffFFFFFF);
			SprIdx2:Draw(sprCut, hero.pos2D.x-XposX+120+33+16, hero.pos2D.y+YposY+3+12);
			end
		end
	end
end


function OnDraw()
if CAMenu.Enabled:Value() then
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.alive and hero.visible then
			if CAMenu.WaypointTracker.Enabled:Value() then
				local posTo2D = hero.posTo:ToScreen();
				if hero.isEnemy then
					if CAMenu.WaypointTracker.TEnemies:Value() then
						Draw.Line(posTo2D.x,posTo2D.y,hero.pos2D.x,hero.pos2D.y,3,Draw.Color(0x70FF0000));
						if posTo2D.onScreen then
							if hero.posTo:DistanceTo(hero.pos) > 100 then
								if CAMenu.WaypointTracker.EPName:Value() then
									Draw.Text(hero.charName,12,posTo2D.x,posTo2D.y,Draw.Color(0x70FF0000));
									end
								if CAMenu.WaypointTracker.EPTime:Value() then
									Draw.Text(tostring(math.ceil(hero.posTo:DistanceTo(hero.pos)/hero.ms)),12,posTo2D.x,posTo2D.y+12,Draw.Color(0x70FF0000));
									end
								end
							end
						end
					else
					if CAMenu.WaypointTracker.TAllies:Value() then
						Draw.Line(posTo2D.x,posTo2D.y,hero.pos2D.x,hero.pos2D.y,3,Draw.Color(0x1042aade));
						if posTo2D.onScreen then
							if hero.posTo:DistanceTo(hero.pos) > 100 then
								if CAMenu.WaypointTracker.EPName:Value() then
									Draw.Text(hero.charName,12,posTo2D.x,posTo2D.y,Draw.Color(0x4042aade));
									end
								if CAMenu.WaypointTracker.EPTime:Value() then
									Draw.Text(tostring(math.ceil(hero.posTo:DistanceTo(hero.pos)/hero.ms)),12,posTo2D.x,posTo2D.y+12,Draw.Color(0x4042aade));
									end
								end
							end
						end
					end
				end
			if CAMenu.SpellTracker.Enabled:Value() then
				if hero.pos2D.onScreen then
					DrawSpellTracking(hero.isEnemy and "TEnemies" or hero.isAlly and "TAllies" or "noidea", hero);
					end
				end
			if CAMenu.ExpTracker.Enabled:Value() and (mapID == SUMMONERS_RIFT) then
				if hero.pos2D.onScreen then
					if hero.isEnemy then
						if CAMenu.ExpTracker.TEnemies:Value() then
							Draw.Rect(hero.pos2D.x-XposX-6,hero.pos2D.y+YposY+6, 188 , 4 ,Draw.Color(0x7A000000));
							lvlData = hero.levelData;
							if (lvlData.lvl > 0) and (lvlData.lvl < 18) then
								totalExp = ExpGain[lvlData.lvl+1] - ExpGain[lvlData.lvl];
								currExp = lvlData.exp - ExpGain[lvlData.lvl];
								Draw.Rect(hero.pos2D.x-XposX-5,hero.pos2D.y+YposY+7, ((currExp/totalExp) * 186) , 2 ,Draw.Color(0x9A983af3));
								else
								Draw.Rect(hero.pos2D.x-XposX-5,hero.pos2D.y+YposY+7, 186 , 2 ,Draw.Color(0x9A983af3));
								end
							end
						else
						if CAMenu.ExpTracker.TAllies:Value() then
							Draw.Rect(hero.pos2D.x-XposX-6,hero.pos2D.y+YposY+6, 188 , 4 ,Draw.Color(0x7A000000));
							lvlData = hero.levelData;
							if (lvlData.lvl > 0) and (lvlData.lvl < 18) then
								totalExp = ExpGain[lvlData.lvl+1] - ExpGain[lvlData.lvl];
								currExp = lvlData.exp - ExpGain[lvlData.lvl];
								Draw.Rect(hero.pos2D.x-XposX-5,hero.pos2D.y+YposY+7, ((currExp/totalExp) * 186) , 2 ,Draw.Color(0x9A983af3));
								else
								Draw.Rect(hero.pos2D.x-XposX-5,hero.pos2D.y+YposY+7, 186 , 2 ,Draw.Color(0x9A983af3));
								end
							end
						end
					end
				end
			end
		end
	end
end

--PrintChat("Champion tracker by Feretorix loaded.")