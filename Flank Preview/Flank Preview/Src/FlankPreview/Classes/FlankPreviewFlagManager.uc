class FlankPreviewFlagManager extends UIUnitFlagManager;

var array<UIUnitFlag> flankedUnitsArr;

function RealizePreviewEndOfMoveLOS(GameplayTileData MoveToTileData)
{
	local int Index;
	local UIUnitFlag kFlag;

    // reset flankedArr to prevent a memory leak
	if (m_arrFlags.length == 0) {
	    flankedUnitsArr.length = 0;
	}

	foreach m_arrFlags(kFlag)
	{
		Index = MoveToTileData.VisibleEnemies.Find('SourceID', kFlag.StoredObjectID);
		if (Index == INDEX_NONE)
		{
			SetSpottedAndFlankedState(kFlag, false, false);
		}
		else
		{
		    kFlag.m_bSpotted = true;

		    // if flanked
			if(class'FlankPreviewVisibilityHelper'.static.IsFlankedByLocation(Index, MoveToTileData))
			{
			    // display yellow icon
		        SetSpottedAndFlankedState(kFlag, true, true);
			}
			else
			{
			    // display red icon
				SetSpottedAndFlankedState(kFlag, true, false);
            }
		}
	}
}

simulated function SetSpottedAndFlankedState(UIUnitFlag kFlag, bool spotted, bool flanked)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local bool m_bFlanked;

	m_bFlanked = (flankedUnitsArr.find(kFlag) != INDEX_NONE);

	if( spotted == kFlag.m_bSpotted && flanked == m_bFlanked) return;

    // save the state
	kFlag.m_bSpotted = spotted;

	if (flanked) {
	    flankedUnitsArr.addItem(kFlag);
	} else {
	    flankedUnitsArr.removeItem(kFlag);
	}

    // display
	myValue.Type = AS_Boolean;
	myValue.b = spotted;
	myArray.AddItem( myValue );

	myValue.Type = AS_Boolean;
    myValue.b = flanked;
    myArray.AddItem( myValue );

	kFlag.Invoke("SetSpottedState", myArray);
}

simulated function RemoveFlag( UIUnitFlag kFlag )
{
	super.RemoveFlag(kFlag);

}
