
class FlankedUnitFlag extends UIUnitFlag;

var bool            m_bFlanked;

simulated function SetSpottedAndFlankedState(bool spotted, bool flanked)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	if( spotted == m_bSpotted && flanked == m_bFlanked) return;

	m_bSpotted = spotted;
	m_bFlanked = flanked;

	myValue.Type = AS_Boolean;
	myValue.b = m_bSpotted;
	myArray.AddItem( myValue );

	myValue.Type = AS_Boolean;
    myValue.b = flanked;
    myArray.AddItem( myValue );

	Invoke("SetSpottedState", myArray);
}

