/**
 * electron-builder設定
 * バックテストエンジンexeを同梱してパッケージ化
 */
module.exports = {
  appId: 'com.strategybricks.builder',
  productName: 'Strategy Bricks Builder',
  directories: {
    output: 'release',
    buildResources: 'build'
  },
  files: [
    'dist/**/*',
    'dist-electron/**/*',
    'package.json'
  ],
  extraResources: [
    {
      // バックテストエンジンexeを同梱
      from: '../python/dist',
      to: 'python',
      filter: ['backtest_engine.exe']
    },
    {
      // EA設定ファイル用ディレクトリ
      from: '../ea/tests',
      to: 'ea/tests',
      filter: ['*.json', '*.md']
    }
  ],
  win: {
    target: [
      {
        target: 'nsis',
        arch: ['x64']
      }
    ],
    icon: 'build/icon.ico'
  },
  nsis: {
    oneClick: false,
    allowToChangeInstallationDirectory: true,
    createDesktopShortcut: true,
    createStartMenuShortcut: true
  }
}
