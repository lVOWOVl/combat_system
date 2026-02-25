# service_locator.gd
# 服务定位器（Autoload单例）
# 提供全局服务访问，如数据加载器、Resource管理等

extends Object

## 服务存储字典
var _services: Dictionary = {}

## 注册服务
## 参数：
##   service_name: 服务名称
##   service_instance: 服务实例
func register_service(service_name: String, service_instance: Object) -> void:
	_services[service_name] = service_instance

## 获取服务
## 参数：
##   service_name: 服务名称
## 返回: 服务实例，如果不存在返回null
func get_service(service_name: String) -> Object:
	return _services.get(service_name, null)

## 注销服务
## 参数：
##   service_name: 服务名称
func unregister_service(service_name: String) -> void:
	_services.erase(service_name)

## 检查服务是否存在
## 参数：
##   service_name: 服务名称
## 返回: 是否存在
func has_service(service_name: String) -> bool:
	return _services.has(service_name)
