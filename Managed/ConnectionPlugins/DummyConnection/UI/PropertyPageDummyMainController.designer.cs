// ------------------------------------------------------------------------------
//  <autogenerated>
//      This code was generated by a tool.
//      Mono Runtime Version: 4.0.30319.17020
// 
//      Changes to this file may cause incorrect behavior and will be lost if 
//      the code is regenerated.
//  </autogenerated>
// ------------------------------------------------------------------------------

namespace MyUniqueNamespace {
	using Monobjc;
	using remojoApi;
	using Monobjc.AppKit;
	
	
	public partial class PropertyPageDummyMainController {
		
partial void ButtonComputerNameEditor_Action(Id sender);

		
		[IBOutlet()]
		[ObjectiveCIVar("buttonColor")]
		public virtual RmColorChooserButton buttonColor {
			get {
				return this.GetInstanceVariable <RmColorChooserButton>("buttonColor");
			}
			set {
				this.SetInstanceVariable <RmColorChooserButton>("buttonColor", value);
			}
		}
		
		[IBOutlet()]
		[ObjectiveCIVar("buttonComputerNameEditor")]
		public virtual NSButton buttonComputerNameEditor {
			get {
				return this.GetInstanceVariable <NSButton>("buttonComputerNameEditor");
			}
			set {
				this.SetInstanceVariable <NSButton>("buttonComputerNameEditor", value);
			}
		}
		
		[IBOutlet()]
		[ObjectiveCIVar("buttonIcon")]
		public virtual RmIconChooserButton buttonIcon {
			get {
				return this.GetInstanceVariable <RmIconChooserButton>("buttonIcon");
			}
			set {
				this.SetInstanceVariable <RmIconChooserButton>("buttonIcon", value);
			}
		}
		
		[IBOutlet()]
		[ObjectiveCIVar("imageViewHeader")]
		public virtual NSImageView imageViewHeader {
			get {
				return this.GetInstanceVariable <NSImageView>("imageViewHeader");
			}
			set {
				this.SetInstanceVariable <NSImageView>("imageViewHeader", value);
			}
		}
		
		[IBOutlet()]
		[ObjectiveCIVar("metadataView")]
		public virtual RoyalObjectMetadataView metadataView {
			get {
				return this.GetInstanceVariable <RoyalObjectMetadataView>("metadataView");
			}
			set {
				this.SetInstanceVariable <RoyalObjectMetadataView>("metadataView", value);
			}
		}
		
		[IBOutlet()]
		[ObjectiveCIVar("textFieldComputerName")]
		public virtual NSTextField textFieldComputerName {
			get {
				return this.GetInstanceVariable <NSTextField>("textFieldComputerName");
			}
			set {
				this.SetInstanceVariable <NSTextField>("textFieldComputerName", value);
			}
		}
		
		[IBOutlet()]
		[ObjectiveCIVar("textFieldComputerNameLabel")]
		public virtual NSTextField textFieldComputerNameLabel {
			get {
				return this.GetInstanceVariable <NSTextField>("textFieldComputerNameLabel");
			}
			set {
				this.SetInstanceVariable <NSTextField>("textFieldComputerNameLabel", value);
			}
		}

		[IBOutlet()]
		[ObjectiveCIVar("textFieldDescription")]
		public virtual NSTextField textFieldDescription {
			get {
				return this.GetInstanceVariable <NSTextField>("textFieldDescription");
			}
			set {
				this.SetInstanceVariable <NSTextField>("textFieldDescription", value);
			}
		}
		
		[IBOutlet()]
		[ObjectiveCIVar("textFieldDescriptionLabel")]
		public virtual NSTextField textFieldDescriptionLabel {
			get {
				return this.GetInstanceVariable <NSTextField>("textFieldDescriptionLabel");
			}
			set {
				this.SetInstanceVariable <NSTextField>("textFieldDescriptionLabel", value);
			}
		}
		
		[IBOutlet()]
		[ObjectiveCIVar("textFieldDisplayName")]
		public virtual NSTextField textFieldDisplayName {
			get {
				return this.GetInstanceVariable <NSTextField>("textFieldDisplayName");
			}
			set {
				this.SetInstanceVariable <NSTextField>("textFieldDisplayName", value);
			}
		}
		
		[IBOutlet()]
		[ObjectiveCIVar("textFieldDisplayNameLabel")]
		public virtual NSTextField textFieldDisplayNameLabel {
			get {
				return this.GetInstanceVariable <NSTextField>("textFieldDisplayNameLabel");
			}
			set {
				this.SetInstanceVariable <NSTextField>("textFieldDisplayNameLabel", value);
			}
		}
		
		[IBOutlet()]
		[ObjectiveCIVar("textFieldHeaderLabel")]
		public virtual NSTextField textFieldHeaderLabel {
			get {
				return this.GetInstanceVariable <NSTextField>("textFieldHeaderLabel");
			}
			set {
				this.SetInstanceVariable <NSTextField>("textFieldHeaderLabel", value);
			}
		}

		[IBOutlet()]
		[ObjectiveCIVar("textFieldPhysicalAddress")]
		public virtual NSTextField textFieldPhysicalAddress {
			get {
				return this.GetInstanceVariable <NSTextField>("textFieldPhysicalAddress");
			}
			set {
				this.SetInstanceVariable <NSTextField>("textFieldPhysicalAddress", value);
			}
		}
		
		[IBOutlet()]
		[ObjectiveCIVar("textFieldPhysicalAddressLabel")]
		public virtual NSTextField textFieldPhysicalAddressLabel {
			get {
				return this.GetInstanceVariable <NSTextField>("textFieldPhysicalAddressLabel");
			}
			set {
				this.SetInstanceVariable <NSTextField>("textFieldPhysicalAddressLabel", value);
			}
		}
		
		[IBAction()]
		[ObjectiveCMessage("buttonComputerNameEditor_Action:")]
		public virtual void __ButtonComputerNameEditor_Action(Id sender) {
			this.ButtonComputerNameEditor_Action(sender);
		}
	}
}
