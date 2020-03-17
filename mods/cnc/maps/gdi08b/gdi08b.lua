--[[
   Copyright 2007-2020 The OpenRA Developers (see AUTHORS)
   This file is part of OpenRA, which is free software. It is made
   available to you under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of
   the License, or (at your option) any later version. For more
   information, see COPYING.
]]


Difficulty = Map.LobbyOption("difficulty")

CivilianCasualties = 0
CiviliansKilledThreshold = { hard = 5, normal = 9, easy = 13 } --total 14
Civilians = { civ1, civ2, civ3, civ4, civ5, civ6, civ7, civ8, civ9, civ10, civ11, civ12, civ13, civ14 }

SamSites = { sam1, sam2, sam3, sam4, sam5 }

HeliDelay = { 170, 0, 130 }
NodHelis = {
	{ delay = DateTime.Seconds(HeliDelay[1]), entry = { DefaultChinookTarget.Location, waypoint14.Location }, types = { "e1", "e1", "e4", "e4", "e4" } }, --TERROR, wp14, attack civilians - alle 170 timeunits
	{ delay = DateTime.Seconds(HeliDelay[2]), entry = { DefaultChinookTarget.Location, waypoint13.Location }, types = { "e3", "e3", "e3", "e4", "e4" } }, --Air1, wp13, attack base - triggered on killed units, Harv, some tanks and some buggys...
	{ delay = DateTime.Seconds(HeliDelay[3]), entry = { DefaultChinookTarget.Location, waypoint0.Location }, types = { "e1", "e3", "e3", "e4", "e4" } } --Air2, wp0, attack base - alle 130 timeunits
}

SendHeli = function(heli)
	units = Reinforcements.ReinforceWithTransport(Nod, "tran", heli.types, heli.entry, { heli.entry[1] })
	Utils.Do(units[2], function(actor)
		actor.Hunt()
		Trigger.OnIdle(actor, actor.Hunt)
		
		--a.AttackMove(PlayerBase.Location)
		--IdleHunt(a)
		--Trigger.OnKilled(actor, KillCounter)
	end)
	if heli.delay == DateTime.Seconds(HeliDelay[2]) then
		return
	end
	Trigger.AfterDelay(heli.delay, function() SendHeli(heli) end)
end
IdleHunt = function(unit) if not unit.IsDead then Trigger.OnIdle(unit, unit.Hunt) end end

--[[
WaypointGroup1 = { waypoint1, waypoint2, waypoint8 }
WaypointGroup2 = { waypoint1, waypoint2, waypoint3, waypoint9 }
WaypointGroup3 = { waypoint1, waypoint2, waypoint3, waypoint10, waypoint11, waypoint12, waypoint6, waypoint13 }
WaypointGroup4 = { waypoint1, waypoint2, waypoint3, waypoint4 }
Patrol1Waypoints = { waypoint11.Location, waypoint10.Location }
Patrol2Waypoints = { waypoint1.Location, waypoint2.Location, waypoint3.Location, waypoint4.Location, waypoint5.Location, waypoint4.Location, waypoint3.Location, waypoint2.Location, waypoint1.Location, waypoint6.Location }

Nod1 = { units = { ['e1'] = 2, ['e3'] = 2 }, waypoints = WaypointGroup1, delay = 40 }
Nod2 = { units = { ['e3'] = 2, ['e4'] = 2 }, waypoints = WaypointGroup2, delay = 50 }
Nod3 = { units = { ['e1'] = 2, ['e3'] = 3, ['e4'] = 2 }, waypoints = WaypointGroup1, delay = 50 }
Nod4 = { units = { ['bggy'] = 2 }, waypoints = WaypointGroup2, delay = 50 }
Nod5 = { units = { ['e4'] = 2, ['ltnk'] = 1 }, waypoints = WaypointGroup1, delay = 50 }
Auto1 = { units = { ['e4'] = 2, ['arty'] = 1 }, waypoints = WaypointGroup1, delay = 50 }
Auto2 = { units = { ['e1'] = 2, ['e3'] = 2 }, waypoints = WaypointGroup2, delay = 50 }
Auto3 = { units = { ['e3'] = 2, ['e4'] = 2 }, waypoints = WaypointGroup1, delay = 50 }
Auto4 = { units = { ['e1'] = 3, ['e4'] = 1 }, waypoints = WaypointGroup1, delay = 50 }
Auto5 = { units = { ['ltnk'] = 1, ['bggy'] = 1 }, waypoints = WaypointGroup1, delay = 60 }
Auto6 = { units = { ['bggy'] = 1 }, waypoints = WaypointGroup2, delay = 50 }
Auto7 = { units = { ['ltnk'] = 1 }, waypoints = WaypointGroup2, delay = 50 }
Auto8 = { units = { ['e4'] = 2, ['bggy'] = 1 }, waypoints = WaypointGroup4, delay = 0 }

Patrols = 
{ 
	grd1 = { units = { ['e3'] = 3 }, waypoints = Patrol1Waypoints, wait = 40, initialWaypointPlacement = { 1 } },
	grd2 = { units = { ['e1'] = 2, ['e3'] = 2, ['e4'] = 2 }, waypoints = Patrol2Waypoints, wait = 20, initialWaypointPlacement = { 4, 10, 1 } }
}

AutoAttackWaves = { Nod1, Nod2, Nod3, Nod4, Nod5, Auto1, Auto2, Auto3, Auto4, Auto5, Auto6, Auto7, Auto8 }

StationaryGuards = { Actor174, Actor173, Actor182, Actor183, Actor184, Actor185, Actor186, Actor187 , Actor199, Actor200, Actor201, Actor202, Actor203, Actor204}

StartStationaryGuards = function()
	Utils.Do(StationaryGuards, function(unit)
		if not unit.IsDead then
			unit.Patrol( { unit.Location } , true, 20)
		end
	end)
end

StartWaves = function()
	SendWaves(1, AutoAttackWaves)
end

SendWaves = function(counter, Waves)
	if counter <= #Waves then
		local team = Waves[counter]
		SendAttackWave(team)
		Trigger.AfterDelay(DateTime.Seconds(team.delay), function() SendWaves(counter + 1, Waves) end)
	end
end

SendAttackWave = function(team)
	for type, amount in pairs(team.units) do
		count = 0
		local actors = Nod.GetActorsByType(type)
		Utils.Do(actors, function(actor)
			if actor.IsIdle and count < amount then
				SetAttackWaypoints(actor, team.waypoints)
				IdleHunt(actor)
				count = count + 1
			end
		end)
	end
end

SetAttackWaypoints = function(actor, waypoints)
	if not actor.IsDead then
		Utils.Do(waypoints, function(waypoint)
			actor.AttackMove(waypoint.Location)
		end)
	end
end

]]

WorldLoaded = function()
	GDI = Player.GetPlayer("GDI")
	Nod = Player.GetPlayer("Nod")

	Camera.Position = DefaultCameraPosition.CenterPosition
	
	--StartStationaryGuards()
	
	--StartAI(nodconyard)

	Trigger.OnObjectiveAdded(GDI, function(p, id)
		Media.DisplayMessage(p.GetObjectiveDescription(id), "New " .. string.lower(p.GetObjectiveType(id)) .. " objective")
	end)

	Trigger.OnObjectiveCompleted(GDI, function(p, id)
		Media.DisplayMessage(p.GetObjectiveDescription(id), "Objective completed")
	end)

	Trigger.OnObjectiveFailed(GDI, function(p, id)
		Media.DisplayMessage(p.GetObjectiveDescription(id), "Objective failed")
	end)

	Trigger.OnPlayerWon(GDI, function()
		Media.PlaySpeechNotification(Nod, "Win")
	end)

	Trigger.OnPlayerLost(GDI, function()
		Media.PlaySpeechNotification(Nod, "Lose")
	end)

	ProtectMoebius = GDI.AddObjective("Protect Dr. Mobius.")
	Trigger.OnKilled(DrMoebius, function()
		GDI.MarkFailedObjective(ProtectMoebius)
	end)
	
	ProtectHospital = GDI.AddObjective("Protect the Hospital.")
	Trigger.OnKilled(Hospital, function()
		GDI.MarkFailedObjective(ProtectHospital)
	end)
	
	ProtectCivilians = GDI.AddObjective("Protect the Civilians.")
	CiviliansKilledThreshold = CiviliansKilledThreshold[Difficulty]
	Utils.Do(Civilians, function(civilian)
		Trigger.OnKilled(civilian, function()
			CivilianCasualties = CivilianCasualties + 1
			if CiviliansKilledThreshold <= CivilianCasualties then
				GDI.MarkFailedObjective(ProtectCivilians)
			end
		end)
	end)
	
	SecureArea = GDI.AddObjective("Destroy the Nod bases.")
	--Kill Mobius
  --Destroy Hospital
  --Eliminate possibility of infection spreading from hospital 
	KillGDI = Nod.AddObjective("Kill all enemies!")
	
	AirSupport = GDI.AddObjective("Destroy the SAM sites to receive air support.", "Secondary", false)
	Trigger.OnAllKilled(SamSites, function()
		GDI.MarkCompletedObjective(AirSupport)
		Actor.Create("airstrike.proxy", true, { Owner = GDI })
	end)

	Actor.Create("flare", true, { Owner = GDI, Location = DefaultFlareLocation.Location })
	
	--StartPatrols()
	
	--Trigger.AfterDelay(DateTime.Minutes(1), function() StartWaves() end) -- DateTime.Minutes(1)
	--Trigger.AfterDelay(DateTime.Minutes(3), function() ProduceInfantry(handofnod) end) -- DateTime.Minutes(3)
	--Trigger.AfterDelay(DateTime.Minutes(3), function() ProduceVehicle(nodairfield) end) -- DateTime.Minutes(3)
	
	local InitialArrivingUnits = { 
		{ units = { Actor252, Actor253, Actor223, Actor225, Actor222, Actor258, Actor259, Actor260, Actor261, Actor254, Actor255, Actor256, Actor257 }, distance = -1 },
		{ units = { Actor218, Actor220, Actor224, Actor226 }, distance = -2 },
		{ units = { Actor218, gdiAPC1 }, distance = -3 }
	}
	
	Utils.Do(InitialArrivingUnits, function(group)
		Utils.Do(group.units, function(unit)
			unit.Move(unit.Location + CVec.New(0, group.distance), 0)
		end)
	end)
	
	Utils.Do(NodHelis, function(heli)
		if heli.delay == DateTime.Seconds(HeliDelay[2]) then -- heli1 comes only when specific units are killed
			return
		end
		Trigger.AfterDelay(heli.delay, function() SendHeli(heli) end)
	end)
	
	-- units destroyed, send heli, eg. harv, tnk, bggy,...
	Trigger.OnKilled(Actor246, function() SendHeli(NodHelis[2]) end)
	Trigger.OnKilled(Actor221, function() SendHeli(NodHelis[2]) end)
	
end

Tick = function()
	if DateTime.GameTime > DateTime.Seconds(5) then
		if GDI.HasNoRequiredUnits()  then
			Nod.MarkCompletedObjective(KillGDI)
		end
		if Nod.HasNoRequiredUnits() then
			GDI.MarkCompletedObjective(SecureArea)
			GDI.MarkCompletedObjective(ProtectMoebius)
			GDI.MarkCompletedObjective(ProtectHospital)
			GDI.MarkCompletedObjective(ProtectCivilians)
		end
	end
end
