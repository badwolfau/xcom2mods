class FlankPreviewFlagManager extends UIUnitFlagManager;

var array<UIUnitFlag> flankedUnitsArr;

function RealizePreviewEndOfMoveLOS(GameplayTileData MoveToTileData)
{
	local int Index;
	local UIUnitFlag kFlag;
	local GameRulesCache_VisibilityInfo VisibilityInfo;
	local XComGameState_Unit SourceUnitState, TargetUnitState;

    // reset flankedArr to prevent a memory leak
	if (m_arrFlags.length == 0) {
	    flankedUnitsArr.length = 0;
	}

//    `log("------------------");
//    `log("CURRENT UNIT = " @ m_lastActiveUnit);

    SourceUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_lastActiveUnit.ObjectID,,-1));
//    `log("CURRENT UNIT hasSquadSight = " @ SourceUnitState.HasSquadSight());

	foreach m_arrFlags(kFlag)
	{
	    TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kFlag.StoredObjectID,,-1));

		Index = MoveToTileData.VisibleEnemies.Find('SourceID', kFlag.StoredObjectID);
		if (Index == INDEX_NONE)
		{
            if (!kFlag.m_bIsFriendly && TargetUnitState != none && SourceUnitState.HasSquadSight() && `XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, TargetUnitState.TileLocation, VisibilityInfo) && VisibilityInfo.bClearLOS)
            {
                displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo);
            }
            else
            {
                // remove icon
                SetSpottedAndFlankedState(kFlag, false, false);
			}
		}
		else
		{
		    VisibilityInfo = MoveToTileData.VisibleEnemies[Index];
            displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo);
		}
	}
}

function displaySpottedIcon(UIUnitFlag kFlag,
                           TTile tile,
                           XComGameState_Unit SourceUnitState,
                           XComGameState_Unit TargetUnitState,
                           GameRulesCache_VisibilityInfo VisibilityInfo)
{
    // if flanked
    if(class'FlankPreviewVisibilityHelper'.static.IsFlankedByLocation(tile, SourceUnitState, TargetUnitState, VisibilityInfo))
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

function SetSpottedAndFlankedState(UIUnitFlag kFlag, bool spotted, bool flanked)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local bool m_bFlanked;

	m_bFlanked = (flankedUnitsArr.find(kFlag) != INDEX_NONE);

	if (spotted == kFlag.m_bSpotted && flanked == m_bFlanked) return;

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
