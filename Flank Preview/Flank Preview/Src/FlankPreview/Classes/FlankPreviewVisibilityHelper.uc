class FlankPreviewVisibilityHelper extends X2TacticalVisibilityHelpers;


//Looks from a location to an interactive object
simulated static function bool CanLocationSeeHackableObj(XComGameState_InteractiveObject HackableObj, GameplayTileData Location)
{
	local GameRulesCache_VisibilityInfo VisibilityInfo;
	
	`XWORLD.CanSeeTileToTile(Location.EventTile, HackableObj.TileLocation, VisibilityInfo);

	if(VisibilityInfo.bClearLOS)
		return true;
	else
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
	local GameRulesCache_VisibilityInfo PeekVisInfo;
	

	History = `XCOMHISTORY;
	
	SourceState = XComGameState_Unit(History.GetGameStateForObjectID(Location.SourceObjectID,, StartAtHistoryIndex));	//Source unit
	
	if(!SourceState.CanFlank() || SourceState.IsMeleeOnly())	//Some units cannot take flanking shots
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
			}

		PeekData = `XWORLD.GetCachedCoverAndPeekData(ttSource);

		for(i=0; i < ArrayCount(PeekData.CoverDirectionInfo); i++)		//Static array loop
		{
			if(PeekData.CoverDirectionInfo[i].bHasCover == 0)		//Old school int as bool
				continue;
			else
			{
				//Check left side
				if(PeekData.CoverDirectionInfo[i].LeftPeek.bHasPeekAround == 1)
				{
					ttSource = PeekData.CoverDirectionInfo[i].LeftPeek.PeekTile;
					`XWORLD.CanSeeTileToTile(ttSource, ttTarget, PeekVisInfo);
					if(PeekVisInfo.CoverDirection == -1)
						return true;

				}
				//Check right side
				if(PeekData.CoverDirectionInfo[i].RightPeek.bHasPeekAround == 1)
				{
					ttSource = PeekData.CoverDirectionInfo[i].RightPeek.PeekTile;
					`XWORLD.CanSeeTileToTile(ttSource, ttTarget, PeekVisInfo);
					if(PeekVisInfo.CoverDirection == -1)
						return true;
				}
			}
		}
	}
		return false;
}


//TODO: Handle both LOS and flanking, include squadsight via below function and distance filter.
//	static event GetAllVisibleEnemiesForPlayer(int PlayerStateObjectID, 
//														out array<StateObjectReference> VisibleUnits,
//														int HistoryIndex = -1,
//														bool IncludeNonUnits = false)


//Function to clamp TTile Z-axis to floor tile for conversion to Vector. Doesn't seem to be needed?
//ttSource.Z = `XWORLD.GetFloorTileZ(ttSource);
