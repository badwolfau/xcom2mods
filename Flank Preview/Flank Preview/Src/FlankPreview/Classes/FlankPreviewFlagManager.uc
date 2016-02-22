class FlankPreviewFlagManager extends UIUnitFlagManager;

function RealizePreviewEndOfMoveLOS(GameplayTileData MoveToTileData)
{
	local int Index;
	local UIUnitFlag kFlag;
	local FlankPreviewUnitFlag kFlank;

	foreach m_arrFlags(kFlag)
	{
		if (kFlank == none)
			kFlank = spawn(class'FlankPreviewUnitFlag', kFlag);

		Index = MoveToTileData.VisibleEnemies.Find('SourceID', kFlag.StoredObjectID);
		if (Index == INDEX_NONE)
		{
			kFlank.FlankPreview(false, kFlag);
			kFlag.RealizeLOSPreview(false);
		}
		else
		{
			if(class'FlankPreviewVisibilityHelper'.static.IsFlankedByLocation(Index, Movetotiledata))
			{
				kFlank.FlankPreview(true, kFlag);
				//RealizeLOSPreview(false); //This doesn't work?
			}
			else
				kFlank.FlankPreview(false, kFlag);
				kFlag.RealizeLOSPreview(true);
		}
	}
}