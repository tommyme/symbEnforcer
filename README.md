# symbEnforcer

## 配置文件
我代码里没写，你自己先创建一下文件： `~/.config/symbEnforcer/config.json`
```json
{
  "myValues": ["Code", "Google Chrome", "Obsidian", "iTerm2", "Xcode","Warp"]
}
```
配置文件可以热加载, 我没有特意处理文件语法错误, 尽量不要整语法错误.

## build
- 可以使用xcodebuild进行build 会生成到 `build/Release/symbEnforcer`
- 可以使用xcode软件 command b进行build 会生成到 `~/Library/Developer/Xcode/DerivedData/${SYMB_ENFORCER_DIR}/Build/Products/Debug/symbEnforcer`
- `xcodebuild -project MyApp.xcodeproj -scheme Release`
- `xcodebuild -scheme symbEnforcer -configuration Debug`
- 想使用swift进行build
## 调试
向list里面添加程序名达到在指定的程序中进行强制英文标点。

不知道程序名可以按键盘上的截屏键 然后查看程序的日志 日志中会打印Application Switcher里面的所有程序名称 然后添加进去就是了

## mmd
后来发现搜狗输入法里面能设置这个, 我真的是mmd了.

## etc
代码大部分由gpt生成