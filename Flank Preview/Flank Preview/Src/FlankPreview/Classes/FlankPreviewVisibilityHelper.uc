class FlankPreviewVisibilityHelper extends X2TacticalVisibilityHelpers;


//Looks from a location to an interactive object
simulated static function bool CanLocationSeeHackableObj(XComGameState_InteractiveObject HackableObj, GameplayTileData Location)
{
	local GameRulesCache_VisibilityInfo VisibilityInfo;
	local XComGameState_Unit SourceState;

	`XWORLD.CanSeeTileToTile(Location.EventTile, HackableObj.TileLocation, VisibilityInfo);
	SourceState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Location.SourceObjectID,,-1));

	if(VisibilityInfo.bClearLOS)
	{
		if(VisibilityInfo.DefaultTargetDist <= (SourceState.GetVisibilityRadius() * 100000)) //MUST TEST - LIKELY TOO SHORT, HACKING HAS A LONG RANGE
			return true;
	}
	return false;
}


//Function that looks for LOS from a unit to an object
simulated static function bool CanLocationSeeObject(int TargetID, GameplayTileData Location)
{
	local GameRulesCache_VisibilityInfo VisibilityInfo;
	local XComGameState_Unit SourceState;

	`XWORLD.CanSeeTileToTile(Location.EventTile, XComGameState_InteractiveObject(`XCOMHISTORY.GetGameStateForObjectID(TargetID,,-1)).TileLocation, VisibilityInfo);
	if(VisibilityInfo.bClearLOS)
	{
		SourceState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Location.SourceObjectID,,-1));

		if(SourceState.HasSquadSight())
			return true;
		else
		{
			if(VisibilityInfo.DefaultTargetDist <= (SourceState.GetVisibilityRadius() * 100000)) //What are these units??
				return true;
		}
	}
	return false;
}


//Function that figures out if the Location can see AND flank the target at TargetIndex
simulated static function bool IsFlankedByLocation(int TargetIndex, GameplayTileData Location, optional int StartAtHistoryIndex = -1)
{
	local XComGameState_Unit TargetState, SourceState;
	local XComGameStateHistory History;
	local TTile ttSource, ttTarget, ttDiff;
	local vector vSource, vTarget;
	local float fCoverAngle;
	local ECoverType TargetCover;
	local CachedCoverAndPeekData PeekData;
	local int i,j, TargetIndexForPeek;
	local array< GameRulesCache_VisibilityInfo > PeekVisInfo;

	History = `XCOMHISTORY;

	SourceState = XComGameState_Unit(History.GetGameStateForObjectID(Location.SourceObjectID,, StartAtHistoryIndex));	//Source unit

	if(!SourceState.CanFlank() || SourceState.IsMeleeOnly())	 //Some units cannot take flanking shots
		return false;

	TargetState = XComGameState_Unit(History.GetGameStateForObjectID(Location.VisibleEnemies[TargetIndex].SourceID,, StartAtHistoryIndex)); //Find the VisibleEnemy[index] we want

	if( TargetState != None && TargetState.CanTakeCover() )		//Must be valid target, target must be able to actually take cover.
	{
		//Check to see if we have a direct flank without peeking
		ttSource = Location.EventTile;
		ttTarget = TargetState.TileLocation;
		vSource = `XWORLD.GetPositionFromTileCoordinates(ttSource);
		vTarget = `XWORLD.GetPositionFromTileCoordinates(ttTarget);
		fCoverAngle = Location.VisibleEnemies[TargetIndex].TargetCoverAngle;
		TargetCover = `XWORLD.GetCoverTypeForTarget(vSource, vTarget, fCoverAngle,);

		if(TargetCover == CT_None)
			return true;

		//Time to check for peeking...
		if(Location.VisibleEnemies[TargetIndex].TargetCover == CT_None)			//If the target is flanking our position, we cannot peek flank them...
			{
				ttDiff.X = abs(ttSource.X - ttTarget.X);						//...unless we're both standing at a corner!
				ttDiff.Y = abs(ttSource.Y - ttTarget.Y);
				if(ttDiff.X > 1 || ttDiff.Y > 1)
					return false;
				//else
				//	return true;		//Not always true in the case of Z axis difference
			}

		PeekData = `XWORLD.GetCachedCoverAndPeekData(ttSource);

		for(i=0; i < ArrayCount(PeekData.CoverDirectionInfo); i++)		//Static array loop
		{
			if(PeekData.CoverDirectionInfo[i].bHasCover == 0)		//Old school int as bool
				continue;
			else
			{
				//CHECK LEFT SIDE
				if(PeekData.CoverDirectionInfo[i].LeftPeek.bHasPeekAround == 1)
				{
					ttSource = PeekData.CoverDirectionInfo[i].LeftPeek.PeekTile;
					vSource = `XWORLD.GetPositionFromTileCoordinates(ttSource);
					GetAllEnemiesForLocation(vSource, SourceState.ControllingPlayer.ObjectID, PeekVisInfo);
					if(PeekVisInfo.Length > 0)
					{
						for(j=0; j < PeekVisInfo.Length; j++)
						{
							if(PeekVisInfo[j].SourceID == TargetState.ObjectID)
								TargetIndexForPeek = j;
						}
						if(PeekVisInfo[TargetIndexForPeek].CoverDirection == -1)	// Investigate for corner case
							return true;
					}
				}
				//CHECK RIGHT SIDE
				if(PeekData.CoverDirectionInfo[i].RightPeek.bHasPeekAround == 1)
				{
					ttSource = PeekData.CoverDirectionInfo[i].RightPeek.PeekTile;
					vSource = `XWORLD.GetPositionFromTileCoordinates(ttSource);
					GetAllEnemiesForLocation(vSource, SourceState.ControllingPlayer.ObjectID, PeekVisInfo);
					if(PeekVisInfo.Length > 0)
					{
					for(j=0; j < PeekVisInfo.Length; j++)
						{
							if(PeekVisInfo[j].SourceID == TargetState.ObjectID)
								TargetIndexForPeek = j;
						}
						if(PeekVisInfo[TargetIndexForPeek].CoverDirection == -1)	// Investigate for corner case
							return true;
					}
				}
			}
		}
	}
		return false;
}


/////// OLD ALMOST WORKING SIMPLER METHOD
/*

simulated static function bool IsFlankedByLocation(int TargetIndex, GameplayTileData Location, optional int StartAtHistoryIndex = -1)
{
	local XComGameState_Unit TargetState, TESTSTATE;
	local XComGameStateHistory History;
	//local GameRulesCache_VisibilityInfo LocationVisInfo;
	
	History = `XCOMHISTORY;
	
	TargetState = XComGameState_Unit(History.GetGameStateForObjectID(Location.VisibleEnemies[TargetIndex].SourceID,, StartAtHistoryIndex)); //Find the VisibleEnemy[index] we want
	
	if( TargetState != None && TargetState.CanTakeCover() )		//Must be valid, must be able to actually take cover (TODO: Test with an Archon or something!)
	{
		if(Location.VisibleEnemies[TargetIndex].CoverDirection == -1) //This seems to work except for peeking ;_;, whereas TargetCover = CT_None shows if the target is currently flanking the tile in question
			return true;
		else
		{
			//if(Locations +/-1 all around have Cover?)
				return true;
		}
	}
		return false;
}
*/