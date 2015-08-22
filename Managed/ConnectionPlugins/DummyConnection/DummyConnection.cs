using System;
using System.Text;

using Monobjc;
using Monobjc.AppKit;
using Monobjc.Foundation;

using remojoApi;
using RoyalDocumentLibrary;

namespace MyUniqueNamespace
{
	[ObjectiveCClass]
	public class DummyConnection : BaseConnectionType
	{
		internal const string PLUGIN_ID = "e41a1e2b-45c1-45f6-a6db-3e99228b86d1";
		internal const string PLUGIN_NAME = "Dummy";

		#region Private Members
		private DummySessionViewController m_sessionViewController;
		#endregion Private Members

		#region Public Members
		public override NSArray ConnectWithOptionsMenuItems
		{
			get {
				NSMutableArray items = NSMutableArray.Array;
				
				items.AddObject(
					new NSMenuItem("Console/Admin Session".TLL().NS(), IntPtr.Zero, ApiUtils.EmptyNSString) {
						RepresentedObject = "ConnectToAdministerOrConsole".NS(),
						State = NSCellStateValue.NSOnState
					}.Autorelease<NSMenuItem>()
				);
				
				return items;
			}
		}

		public override NSArray TabContextMenuItems 
		{
			get {
				NSMutableArray items = NSMutableArray.Array;

				items.AddObject(
					new NSMenuItem("Show Message".TLL().NS(), "showMessageItem_action:".ToSelector(), ApiUtils.EmptyNSString) {
						Target = this
					}.Autorelease<NSMenuItem>()
				);

				return items.Copy<NSArray>().Autorelease<NSArray>();
			}
			set { }
		}

		public override bool SupportsBulkAdd
		{
			get {
				return true;
			}
		}
		#endregion Public Members
		
		#region Events
		public override event ConnectionStatusChangedHandler ConnectionStatusChanged;
		#endregion Events

		#region ObjC Initialization Stuff
		public static readonly Class DummyConnectionClass = Class.Get(typeof(DummyConnection));
		public DummyConnection() { }
		public DummyConnection(IntPtr nativePointer) : base(nativePointer) { }

		public override void InitBasic()
		{
			ConnectionIcons.DefaultIcon = ImageAccessor.GetIcon("Icon.png");
			ConnectionIcons.InactiveIcon = ImageAccessor.GetIcon("IconInactive.png");
			ConnectionIcons.IntermediateIcon = ImageAccessor.GetIcon("IconProgress.png");
			ConnectionIcons.ActiveIcon = ImageAccessor.GetIcon("IconActive.png");
		}
		
		[ObjectiveCMessage("dealloc")]
		public override void Dealloc()
		{
			this.LogDealloc(true);

			if (m_sessionViewController != null) {
				SessionView = null;

				m_sessionViewController.Release();
				m_sessionViewController = null;
			}

			if (CurrentScreenshot != null) {
				CurrentScreenshot.Release();
				CurrentScreenshot = null;
			}
			
			this.SendMessageSuper(DummyConnectionClass, "dealloc");
		}
		#endregion ObjC Initialization Stuff
		
		#region ObjC Constructor
		public override Id InitConnectionType(RoyalConnection data, NSTabViewItem tabViewItem, NSWindow parentWindow)
		{
			Data = data;
			TabViewItem = tabViewItem;

			return this;
		}
		#endregion ObjC Constructor

		#region Tab Context Menu Items
		[ObjectiveCMessage("showMessageItem_action:")]
		public void ShowMessageItem_Action(Id sender)
		{
			if (m_sessionViewController != null) {
				m_sessionViewController.ShowMessage();
			}
		}
		#endregion Tab Context Menu Items
		
		#region Connection Handling
		public override void Connect()
		{
			LogConnectionInfo();

			NativeSessionStatusChanged(ConnectionStatusArguments.ArgumentsWithStatus(RtsConnectionStatus.rtsConnectionConnecting));

			// Delay by 1 second to demonstrate progress
			ApiUtils.ExecuteAfterDelay(() => { 
				m_sessionViewController = new DummySessionViewController();
				SessionView = m_sessionViewController.View;

				NativeSessionStatusChanged(ConnectionStatusArguments.ArgumentsWithStatus(RtsConnectionStatus.rtsConnectionConnected));
			}, 1000);
		}

		private void LogConnectionInfo()
		{
			RoyalRDSConnection rdpData = Data as RoyalRDSConnection;

			bool autologon = rdpData.TemporaryGet(() => { return rdpData.CredentialAutologon; });
			CredentialInfo effectiveCred = rdpData.TemporaryGet(() => { return rdpData.GetEffectiveCredential(); });

			string hostname = rdpData.TemporaryGet(() => { return rdpData.URI.ResolveTokensApi(rdpData); });
			int port = rdpData.TemporaryGet(() => { return rdpData.RDPPort; });

			string username = string.Empty;
			string password = string.Empty;

			if (autologon && effectiveCred != null) {
				username = effectiveCred.Username;
				password = effectiveCred.Password;
			}

			int screenWidth = 0;
			int screenHeight = 0;

			rdpData.TemporaryAction(() => {
				if (rdpData.DesktopWidth == 0 && rdpData.DesktopHeight == 0) {
					NSView connectionPlaceholderView = TabViewItem.View.CastTo<NSView>();

					screenWidth = (int)connectionPlaceholderView.Frame.Width;
					screenHeight = (int)connectionPlaceholderView.Frame.Height;
				} else {
					screenWidth = rdpData.DesktopWidth;
					screenHeight = rdpData.DesktopHeight;
				}
			});

			bool console = rdpData.TemporaryGet(() => { return rdpData.ConnectToAdministerOrConsole; });

			StringBuilder details = new StringBuilder();
			details.AppendLine(string.Format("Hostname: {0}", hostname));
			details.AppendLine(string.Format("Port: {0}", port));
			details.AppendLine(string.Format("Console: {0}", console));
			details.AppendLine(string.Format("AutoLogon: {0}", autologon));
			details.AppendLine(string.Format("Username: {0}", username));
			details.AppendLine(string.Format("Password: {0}", password));
			details.AppendLine(string.Format("Resolution: {0}x{1}", screenWidth, screenHeight));

			ApiUtils.Log.Add(new RoyalLogEntry() {
				Severity = RoyalLogEntry.Severities.Debug, 
				Action = "DummyConnection",
				PluginID = PLUGIN_ID,
				PluginName = PLUGIN_NAME,
				Message = "Connection Info",
				Details = details.ToString()
			});
		}

		public override void Disconnect()
		{
			NativeSessionStatusChanged(ConnectionStatusArguments.ArgumentsWithStatus(RtsConnectionStatus.rtsConnectionDisconnecting));

			// Delay by 1 second to demonstrate progress
			ApiUtils.ExecuteAfterDelay(() => { 
				NativeSessionStatusChanged(ConnectionStatusArguments.ArgumentsWithStatus(RtsConnectionStatus.rtsConnectionClosed));
			}, 1000);
		}

		[ObjectiveCMessage("sessionStatusChanged:")]
		public override void NativeSessionStatusChanged(ConnectionStatusArguments args)
		{
			ConnectionStatus = args.Status;

			ConnectionStatusChangedHandler ev = ConnectionStatusChanged;
			
			if (ev != null) {
				ev(this, args);
			}
		}
		#endregion Connection Handling

		#region Other Stuff
		public override void Focus()
		{
			if (m_sessionViewController != null) {
				m_sessionViewController.Focus();
			}
		}
		
		public override NSImage GetScreenshot()
		{
			NSAutoreleasePool pool = new NSAutoreleasePool();

			try {
				if (CurrentScreenshot != null) {
					CurrentScreenshot.Release();
					CurrentScreenshot = null;
				}

				NSImage img = null;

				if (m_sessionViewController != null) {
					img = m_sessionViewController.GetScreenshot();
				}

				if (img != null) {
					CurrentScreenshot = img.Retain<NSImage>();
				}
			} catch (Exception ex) {
				ApiUtils.Log.Add(new RoyalLogEntry() {
					Severity = RoyalLogEntry.Severities.Debug,
					Action = RoyalLogEntry.ACTION_PLUGIN,
					PluginName = PLUGIN_NAME,
					PluginID = PLUGIN_ID,
					Message = "Error while getting screenshot",
					Details = ex.ToString()
				});
			} finally {
				if (pool != null) {
					pool.Drain();
					pool = null;
				}
			}

			return CurrentScreenshot;
		}
		#endregion Other Stuff
	}
}