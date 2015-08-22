using Monobjc.Foundation;
using Monobjc.AppKit;

using remojoApi;

namespace MyUniqueNamespace
{
	internal static class Language
	{
		private static NSBundle m_pluginBundle;
		private static NSBundle PluginBundle
		{
			get {
				if (m_pluginBundle == null) {
					m_pluginBundle = ApiUtils.GetPluginBundleByType(typeof(Language));
				}

				return m_pluginBundle;
			}
		}

		private static string Get(string text)
		{
			return ApiLanguage.Get(PluginBundle, text);
		}

		private static string GetFormat(string text, params object[] args)
		{
			return ApiLanguage.GetFormat(PluginBundle, text, args);
		}

		internal static string TranslateLocal(this string text)
		{
			return Language.Get(text);
		}
		internal static string TLL(this string text)
		{
			return text.TranslateLocal();
		}

		internal static string TranslateLocal(this string text, params object[] args)
		{
			return Language.GetFormat(text, args);
		}
		internal static string TLL(this string text, params object[] args)
		{
			return text.TranslateLocal(args);
		}
	}

	internal static class ImageAccessor
	{
		private static ImageStore m_store;
		private static ImageStore Store 
		{ 
			get {
				if (m_store == null) {
					m_store = new ImageStore(typeof(ImageAccessor), "MyUniqueNamespace.Resources", string.Empty);
				}

				return m_store;
			}
		}

		internal static RmIcon GetIcon(string name)
		{
			return Store.IconFromResource("Icons." + name);
		}

		internal static NSImage GetImage(string name)
		{
			return GetImage(name, false);
		}

		internal static NSImage GetImage(string name, bool template)
		{
			return GetImage(name, template, false);
		}

		internal static NSImage GetImage(string name, bool template, bool isVector)
		{
			NSImage img = Store.ImageFromResources(name, null, isVector);
			img.IsTemplate = template;

			return img;
		}
	}
}