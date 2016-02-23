class FlankPreviewFlagManager extends UIUnitFlagManager;

function RealizePreviewEndOfMoveLOS(GameplayTileData MoveToTileData)
{
	local int Index;
	local UIUnitFlag kFlag;
	local FlankedUnitFlag kFlankUnitFlag;

	foreach m_arrFlags(kFlag)
	{
	    kFlankUnitFlag = FlankedUnitFlag(kFlag);
		Index = MoveToTileData.VisibleEnemies.Find('SourceID', kFlag.StoredObjectID);
		if (Index == INDEX_NONE)
		{
			kFlankUnitFlag.SetSpottedAndFlankedState(false, false);
		}
		else
		{
		    // if flanked
			if(class'FlankPreviewVisibilityHelper'.static.IsFlankedByLocation(Index, MoveToTileData))
			{
			    // display yellow icon
		        kFlankUnitFlag.SetSpottedAndFlankedState(true, true);
			}
			else
			{
			    // display red icon
				kFlankUnitFlag.SetSpottedAndFlankedState(true, false);
            }
		}
	}
}