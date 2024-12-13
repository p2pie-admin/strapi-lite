module.exports = {
  "import-export-entries": {
    enabled: true,
  },
  "drag-drop-content-types": {
    enabled: true,
  },
  i18n: {
    enabled: true,
    config: {
      defaultLocale: "ru",
      locales: ["ru", "en"], // Add other locales if needed
    },
  },
  // migrations: {
  //   enabled: true,
  //   config: {
  //     autoStart: true,
  //     migrationFolderPath: "migrations",
  //   },
  // },
  upload: {
    config: {
      provider: "local",
      providerOptions: {
        sizeLimit: 300 * 1024 * 1024, // 300kb
      },
    },
  },
  transformer: {
    enabled: true,
    config: {
      prefix: "/api/",
      responseTransforms: {
        removeAttributesKey: true,
        removeDataKey: true,
      },
    },
  },
};
