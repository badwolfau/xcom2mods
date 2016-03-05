class GotchaVisibilityHelper extends X2TacticalVisibilityHelpers;

//Function that figures out if the Location can see AND flank the target
simulated static function bool IsFlankedByLocation(TTile ttSource,
                                                   XComGameState_Unit SourceUnitState,
                                                   XComGameState_Unit TargetUnitState,
                                                   GameRulesCache_VisibilityInfo VisibilityInfo)
{
	local TTile ttTarget, ttDiff;
	local vector vSource, vTarget;
	local float fCoverAngle;
	local ECoverType TargetCover;
	local CachedCoverAndPeekData PeekData;
	local int i;
	local GameRulesCache_VisibilityInfo PeekVisInfo;
	

	if(!SourceUnitState.CanFlank() || !SourceUnitState.GetMyTemplate().CanFlankUnits || SourceUnitState.IsMeleeOnly())	//Some units cannot take flanking shots
		return false;
	
	if( TargetUnitState != None && TargetUnitState.CanTakeCover() )		//Must be valid target, target must be able to actually take cover.
	{
		//Check to see if we have a direct flank without peeking
		ttTarget = TargetUnitState.TileLocation;
		vSource = `XWORLD.GetPositionFromTileCoordinates(ttSource);
		vTarget = `XWORLD.GetPositionFromTileCoordinates(ttTarget);
		fCoverAngle = VisibilityInfo.TargetCoverAngle;
		TargetCover = `XWORLD.GetCoverTypeForTarget(vSource, vTarget, fCoverAngle,);
		
		if(TargetCover == CT_None)
			return true;

		//Time to check for peeking...
		if(VisibilityInfo.TargetCover == CT_None)			//If the target is flanking our position, we cannot peek flank them...
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

