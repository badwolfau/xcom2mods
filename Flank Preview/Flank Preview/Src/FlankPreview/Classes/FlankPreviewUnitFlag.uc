class FlankPreviewUnitFlag extends UIUnitFlag;

simulated function FlankPreview(bool bFlanked, UIUnitFlag FlagPanel)
{
	local UIBGBox FlankMarker;
	super.InitPanel(); //Needed?

	FlankMarker = UIBGBox(FlagPanel.GetChildByName('FlankedMarker', false));

	if(bFlanked)
	{
		if(FlankMarker == none) //Old stupid way: if(ParentPanel.GetChildByName('FlankedMarker', false) == none) 
		{
			FlankMarker = Spawn(class'UIBGBox', FlagPanel).InitBG('FlankedMarker', 3, -56, 23, 23,);
			FlankMarker.SetBGColor("yellow_highlight");
			FlankMarker.SetAlpha(50);
			FlankMarker.SetRotationDegrees(45.0);
		}
		else
			FlankMarker.Show();
	}
	else
	{
		if(FlankMarker != none)
			FlankMarker.Hide();
	}
}