#!/bin/sh

action=$1

if [ "$action" = "on" ];then
	ubus send passwall.switch '{"action":"on"}'
fi

if [ "$action" = "off" ];then
	ubus send passwall.switch '{"action":"off"}'
fi

sleep 10
