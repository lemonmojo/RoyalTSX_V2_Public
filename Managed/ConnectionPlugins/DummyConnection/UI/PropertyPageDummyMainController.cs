using System;

using Monobjc;
using Monobjc.AppKit;
using Monobjc.Foundation;

using RoyalDocumentLibrary;
using remojoApi;
using RoyalCommon.Utils;

namespace MyUniqueNamespace
{
	[ObjectiveCClass]
	public partial class PropertyPageDummyMainController : RmPropertyPageBase
	{
		private NSResponder m_prevResponder;

		public override string Name { get { return "Dummy".TL(); } }
		public override RmIcon Icon { get { return ImageAccessor.GetIcon("Icon.png"); } }
		public override bool SupportsBulkEdit { get { return true; } }

		private static NSImage m_listIcon;
		public static NSImage ListIcon 
		{
			get {
				if (m_listIcon == null) { m_listIcon = ApiUtils.GetTintedIconForPropertiesView(ImageAccessor.GetIcon("Icon.png")).Retain<NSImage>(); }
				return m_listIcon;
			}
		}

		public RmIconChooserButton IconButton { get { return buttonIcon; } }
		public RmColorChooserButton ColorButton { get { return buttonColor; } }
		
		public static readonly Class PropertyPageDummyMainControllerClass = Class.Get(typeof(PropertyPageDummyMainController));
		public PropertyPageDummyMainController() { }
		public PropertyPageDummyMainController(IntPtr nativePointer) : base(nativePointer) { }
		
		public override Id InitPropertyPage()
		{
			this.InitNib("PropertyPageDummyMain", ApiUtils.GetPluginBundleByType(this.GetType()));
			return base.InitPropertyPage();
		}
		
		[ObjectiveCMessage("dealloc")]
		public override void Dealloc()
		{
			NSNotificationCenter.DefaultCenter.RemoveObserver(this);
			this.SendMessageSuper(PropertyPageDummyMainControllerClass, "dealloc");
		}
		
		[ObjectiveCMessage("loadView")]
		public override void LoadView()
		{
			this.SendMessageSuper(PropertyPageDummyMainControllerClass, "loadView");
			
			PropertyFields.Add(new RmPropertyPageColorChooserButtonField() {
				View = ColorButton,
				CanToggleEnabled = true,
				AvailableInBulkEditMode = true
			});

			PropertyFields.Add(new RmPropertyPageIconButtonField() {
				View = IconButton,
				CanToggleEnabled = true,
				AvailableInBulkEditMode = true
			});

			PropertyFields.Add(new RmPropertyPageDummyField() {
				View = imageViewHeader,
				Image = Icon.Icon48
			});

			PropertyFields.Add(new RmPropertyPageDummyField() {
				LabelView = textFieldDescription,
				LabelText = "With a Remote Desktop connection you can connect to remote computers supporting RDP (Remote Desktop Protocol, Standard Port is 3389). You can change the port in the Advanced section.".TLL()
			});

			PropertyFields.Add(new RmPropertyPageStringTextField() {
				PropertyName = "Name",
				View = textFieldDisplayName,
				PlaceholderText = "Display Name".TL(),
				LabelView = textFieldDisplayNameLabel,
				LabelText = "Display Name:".TL(),
				FocusField = true,
				DisabledIfDefaultSetting = true,
				CanToggleEnabled = true,
				ValidationCallback = (field) => {
					string retVal = string.Empty;

					if (!field.CurrentObject.IsDefaultSetting &&
					    !IsInBulkEditMode) {
						bool isDisplayNameRequired = !IsInBulkAddMode;
						bool displayNameOk = !NSString.IsNullOrEmpty(textFieldDisplayName.StringValue);

						if (isDisplayNameRequired && 
							!displayNameOk) {
							retVal = "The \"Display Name\" must not be empty.".TL();
						}
					}

					return retVal;
				},
				SaveSetObjectValueCallback = (field, obj) => {
					if (!obj.IsDefaultSetting) {
						field.SetObjectValue(obj);
					}
				}
			});

			PropertyFields.Add(new RmPropertyPageStringTextField() {
				PropertyName = "URI",
				View = textFieldComputerName,
				PlaceholderText = "Computer Name (IP/FQDN)".TL(),
				LabelView = textFieldComputerNameLabel,
				LabelText = "Computer Name:".TL(),
				DisabledIfDefaultSetting = true,
				CanToggleEnabled = true,
				ToggleEnabledCallback = (field, enabled) => {
					field.View.CastTo<NSControl>().IsEnabled = enabled;
					field.LabelView.CastTo<NSControl>().IsEnabled = enabled;
				},
				ValidationCallback = (field) => {
					string retVal = string.Empty;

					if (!field.CurrentObject.IsDefaultSetting &&
					    !IsInBulkEditMode) {
						bool computerNameOk = !NSString.IsNullOrEmpty(textFieldComputerName.StringValue);

						if (!computerNameOk) {
							retVal = "The \"Computer Name\" must not be empty.".TLL();
						}
					}

					return retVal;
				},
				LoadSetUiValueCallback = (field, obj) => {
					buttonComputerNameEditor.IsEnabled = (!obj.IsDefaultSetting && EditMode == ObjectEditMode.EditMode_New);

					field.SetUiValue(field.GetObjectValue(obj));
				},
				SaveSetObjectValueCallback = (field, obj) => {
					if (!obj.IsDefaultSetting) {
						field.SetObjectValue(obj);
					}
				}
			});

			PropertyFields.Add(new RmPropertyPageStringTextField() {
				PropertyName = "Description",
				View = textFieldDescription,
				PlaceholderText = "Description".TL(),
				LabelView = textFieldDescriptionLabel,
				LabelText = "Description:".TL(),
				CanToggleEnabled = true,
				AvailableInBulkEditMode = true
			});

			PropertyFields.Add(new RmPropertyPageStringTextField() {
				PropertyName = "PhysicalAddress",
				View = textFieldPhysicalAddress,
				PlaceholderText = "Physical Address".TL(),
				LabelView = textFieldPhysicalAddressLabel,
				LabelText = "Physical Address:".TL(),
				CanToggleEnabled = true,
				AvailableInBulkEditMode = true
			});

			PropertyFields.Add(new RmPropertyPageMetaDataField() {
				PropertyName = "MetaData",
				View = metadataView
			});

			NSNotificationCenter.DefaultCenter.AddObserverSelectorNameObject(this, "windowDidUpdate:".ToSelector(), NSWindow.NSWindowDidUpdateNotification, this.View.Window);
		}

		[ObjectiveCMessage("windowDidUpdate:")]
		public void WindowDidUpdate(NSNotification notification)
		{
			if (View != null &&
			    View.Window != null &&
			    View.Window.FirstResponder != null) {
				NSTextField tv = ApiUtils.GetFirstResponderTextField(View.Window);
				
				if (tv != null) {
					if (m_prevResponder != tv &&
					    ApiUtils.IsTextFieldFirstResponder(View.Window, textFieldComputerName) &&
						NSString.IsNullOrEmpty(textFieldComputerName.StringValue) &&
						!NSString.IsNullOrEmpty(textFieldDisplayName.StringValue)) {
						textFieldComputerName.StringValue = textFieldDisplayName.StringValue;
					}
					
					m_prevResponder = tv;
				} else {
					m_prevResponder = View.Window.FirstResponder;
				}
			}
		}

		partial void ButtonComputerNameEditor_Action(Id sender)
		{
			string computers = RmComputerPicker.Show(View.Window, new RmComputerPickerArguments() {
				BonjourEnabled = false,
				CustomEntryEnabled = EditMode == ObjectEditMode.EditMode_New,
				CanAddMultiple = EditMode == ObjectEditMode.EditMode_New,
				CurrentHosts = textFieldComputerName.StringValue
			});
			
			if (!string.IsNullOrWhiteSpace(computers)) {
				string[] computerLines = computers.Split(new string[] { "\r\n", "\n", "\r" }, StringSplitOptions.RemoveEmptyEntries);
				
				if (computerLines.Length == 1) {
					RoyalRDSConnection con = new RoyalRDSConnection(null);
					con.ExtendWithTaggedComputerString(computerLines[0]);
					
					if (!string.IsNullOrWhiteSpace(con.Name)) {
						textFieldDisplayName.StringValue = con.Name.NS();
					}
					
					if (!string.IsNullOrWhiteSpace(con.Description)) {
						textFieldDescription.StringValue = con.Description.NS();
					}
					
					if (!string.IsNullOrWhiteSpace(con.URI)) {
						textFieldComputerName.StringValue = con.URI.NS();
						CheckIfIsInBulkAddMode();
					}
				} else if (computerLines.Length > 1) {
					if (EditMode == ObjectEditMode.EditMode_New) {
						string hostsJoined = string.Empty;
						
						foreach (string host in computerLines) {
							hostsJoined += host + ";";
						}
						
						if (hostsJoined.EndsWith(";")) {
							hostsJoined = hostsJoined.Substring(0, hostsJoined.LastIndexOf(";"));
						}
						
						textFieldComputerName.StringValue = hostsJoined.NS();
						CheckIfIsInBulkAddMode();
					} else {
						RmMessageBox.Show(
							RmMessageBoxType.WarningMessage,
							this.View.Window, 
							"Warning".TL(),
							"Bulk-add can only be used when adding new connections.".TL(),
							"OK".TL()
						);
					}
				}
			}
		}
		
		[ObjectiveCMessage("controlTextDidChange:")]
		public void ControlTextDidChange(NSNotification aNotification)
		{
			if (aNotification.Object.CastTo<NSObject>().IsKindOfClass(NSTextField.NSTextFieldClass) &&
			    aNotification.Object == textFieldComputerName) {
				CheckIfIsInBulkAddMode();
			}
		}
		
		private bool IsInBulkAddMode 
		{
			get {
				return (
					EditMode == ObjectEditMode.EditMode_New &&
					textFieldComputerName.StringValue.ToUTF8String().Contains(";")
				);
			}
		}
		
		private void CheckIfIsInBulkAddMode()
		{
			if (IsInBulkAddMode) {
				textFieldDisplayName.StringValue = ApiUtils.EmptyNSString;
				textFieldDisplayName.IsEnabled = false;
			} else {
				textFieldDisplayName.IsEnabled = true;
			}
		}
	}
}