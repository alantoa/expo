export type SerialAsset = {
  // 'styles.css'
  originFilename: string;
  // '_expo/static/css/bc6aa0a69dcebf8e8cac1faa76705756.css'
  filename: string;
  // '\ndiv {\n    background: cyan;\n}\n\n'
  source: string;
  type: 'css' | 'js' | 'map' | 'json';

  metadata: {
    hmrId?: string;
    isAsync?: boolean;
    modulePaths?: string[];
    paths?: Record<string, Record<string, string>>;
    // React client reference from the static babel pass.
    reactClientReferences?: string[];
    // DOM Component references from the static babel pass.
    expoDomComponentReferences?: string[];
    requires?: string[];
  };
};
