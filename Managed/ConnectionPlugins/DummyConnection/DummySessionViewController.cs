using System;

using Monobjc;
using Monobjc.Foundation;
using Monobjc.AppKit;

using remojoApi;

namespace MyUniqueNamespace
{
	[ObjectiveCClass]
	public class DummySessionViewController : NSViewController
	{
		public static readonly Class DummySessionViewControllerClass = Class.Get(typeof(DummySessionViewController));
		public DummySessionViewController(IntPtr nativePointer) : base(nativePointer) { }
		public DummySessionViewController(NSString nibNameOrNil, NSBundle nibBundleOrNil) : base(nibNameOrNil, nibBundleOrNil)  { }

		public DummySessionViewController()
		{
			CreateSessionView();
		}

		private void CreateSessionView()
		{
			View = new NSImageView() {
				Image = ImageAccessor.GetIcon("Icon.png").Icon256
			}.Autorelease<NSImageView>();
		}

		[ObjectiveCMessage("dealloc")]
		public override void Dealloc()
		{
			this.LogDealloc();

			this.SendMessageSuper(DummySessionViewControllerClass, "dealloc");
		}

		public void Focus()
		{
			if (View != null &&
				View.Window != null) {
				View.Window.MakeFirstResponder(View);
			}
		}

		public NSImage GetScreenshot()
		{
			if (View == null) {
				return null;
			}

			NSImageView imageView = View.CastTo<NSImageView>();

			if (imageView == null) {
				return null;
			}

			NSImage image = imageView.Image;

			if (image != null) {
				return image.Copy<NSImage>().Autorelease<NSImage>();
			}

			return null;
		}

		public void ShowMessage()
		{
			RmMessageBox.ShowNonModal(
				RmMessageBoxType.InformationMessage,
				View.Window,
				"Information".TL(),
				"Hello World!".TLL(),
				"OK".TL()
			);
		}
	}
}