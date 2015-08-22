using remojoApi;
using RoyalDocumentLibrary;

namespace MyUniqueNamespace
{
	public class DummyPropertyPages : ConnectionPropertyPageCollection
	{
		public DummyPropertyPages()
		{
			Name = "Dummy Connection Settings".TLL();
			TemplateName = "Dummy Template Settings".TLL();
			Icon = ImageAccessor.GetIcon("Icon.png");
			HandledObjectType = typeof(RoyalRDSConnection);
			SupportsConnectionCredentials = true;
			SupportsWindowMode = true;
			
			// Dummy
			SourceListItem itemDummyCat = new SourceListItem("Dummy".TL()) {
				IsCategory = true
			};

			InsertCommonCategoryAfter = itemDummyCat;
			
			IPropertyPage propPageDummyMain = new PropertyPageDummyMainController().InitPropertyPage() as IPropertyPage;
			itemDummyCat.MutableChildNodes.AddObject(propPageDummyMain.ListItem);

			// Set Properties
			DefaultItem = propPageDummyMain.ListItem;
			
			PropertyPages.Add(propPageDummyMain);
			
			ListItems.Add(itemDummyCat);
		}
	}
}