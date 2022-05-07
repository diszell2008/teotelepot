#!/usr/bin/env python

import sys
import time
import telebot
from importlib import reload

import logging
import subprocess
from logging import handlers
from pprint import pprint
import re
import socket

# Adjust this section
# -----------------------------------------------------------------
TOKEN="5357644253:AAESJpHKWzeaE3xLqu7WktmJrKrVYxcOyYQ"
admin_uid = -1001728969047
interval = 10
# -----------------------------------------------------------------
bot = telebot.TeleBot(TOKEN, parse_mode=None) # You can set parse_mode by default. HTML or MARKDOWN


#reload(sys)
#sys.setdefaultencoding('utf8')
if sys.version[0] == '2':
    reload(sys)
    sys.setdefaultencoding("utf-8")

def run_shell_command(cmd):
    logger.info("--> cmd line : "+cmd)
    response = ""
    p = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    for line in p.stdout.readlines():
        logger.info("--> output : "+str(line))
        response = response + str(line)
    logger.info("shell response : "+str(response))
    return response


def handle(msg):
    content_type, chat_type, chat_id = telepot.glance(msg)
    #pprint(msg)
    parse = msg['text'].split(' ')
    if len(parse) < 2:
        logger.info("Invalid command")
        return
    passcode = msg['text'][0]
    cmd = msg['text'].split(' ', 1)[1]

    if msg['from']['username'] != admin_username and msg['from']['id'] != admin_uid and passcode == admin_passcode:
        logger.info("un-authorized command from: "+msg['from']['username']+" cmd: "+cmd)
        return

    if content_type == 'text':
        ret = run_shell_command(cmd)
        # max telegram message is 4096
        # https://core.telegram.org/method/messages.send_message
        if len(ret) > 4095:
            ret = ret[:4000]+"\n\n...message is truncated..."
        bot.send_message(chat_id, cmd+": "+ret)

def checkFarm():
    ret = run_shell_command("screen -ls | grep farm | awk '{print $1}' | sort | tail -1")
    if ret.find("farm")!=-1:
        logger.info("Found Farm")
        # bot.send_message(admin_uid, socket.gethostname()+ ": Farm Chạy Rồi Nè")
    else:
        logger.info("Chet CMN Farn Roi")
        bot.send_message(admin_uid, socket.gethostname()+ ": Chết cmn Farm Rồi Nè")
    return ""

def checkNode():
    ret = run_shell_command("screen -ls | grep node | awk '{print $1}' | sort | tail -1")
    if ret.find("node")!=-1:
        logger.info("Found Node")
        # bot.send_message(admin_uid, socket.gethostname()+ ": Node Chạy Rồi Nè")
    else:
        logger.info("Chet CMN Node Roi")
        bot.send_message(admin_uid, socket.gethostname()+ ": Chết cmn Node Rồi Nè")
    return ""

def checkNodeStartup():
    ret = run_shell_command("screen -ls | grep node | awk '{print $1}' | sort | tail -1")
    if ret.find("node")!=-1:
        logger.info("Found Node")
        bot.send_message(admin_uid, socket.gethostname()+ ": Node Chạy Rồi Nè")
    else:
        logger.info("Chet CMN Node Roi")
        bot.send_message(admin_uid, socket.gethostname()+ ": Chết cmn Node Rồi Nè")
    
    ret = run_shell_command("screen -ls | grep farm | awk '{print $1}' | sort | tail -1")
    if ret.find("farm")!=-1:
        logger.info("Found Farm")
        bot.send_message(admin_uid, socket.gethostname()+ ": Farm Chạy Rồi Nè")
    else:
        logger.info("Chet CMN Farn Roi")
        bot.send_message(admin_uid, socket.gethostname()+ ": Chết cmn Farm Rồi Nè")
    
    return ""


def check_all():
    ret = checkNode()
    if ret != "":
        bot.send_message(admin_uid, ret)
    ret = checkFarm()
    if ret != "":
        bot.send_message(admin_uid, ret)
    return


if __name__ == "__main__":

    @bot.message_handler(commands=['start', 'help'])
    def send_welcome(message):
        bot.reply_to(message, "Howdy, how are you doing?")

    @bot.message_handler(func=lambda message: True)
    def echo_all(message):
        bot.reply_to(message, message.text)

    # bot.infinity_polling()
    

    logger = logging.getLogger(__name__)
    LOG_FORMAT = "%(levelname) -10s %(asctime)s %(name) -15s %(funcName) -20s %(lineno) -5d: %(message)s"
    hdlr = handlers.RotatingFileHandler(filename='<SET THIS:Location of log file>', mode='a', maxBytes=100000000, backupCount=20, encoding='utf8')
    hdlr.setFormatter(logging.Formatter(LOG_FORMAT))
    logging.getLogger().addHandler(hdlr)
    logging.getLogger().setLevel(logging.INFO)

    logger.info("Program started")
    print ('Listening ...')
    
    bot.send_message(admin_uid, socket.gethostname()+ ": Bot Chạy Rồi Nè")
    checkNodeStartup()

    # Keep the program running.
    starttime=int(time.time())
    while 1:
        curtime = int(time.time())
        if curtime - starttime > interval:
            # bot.send_message(admin_uid, socket.gethostname()+ "Still Alive")
            check_all()
            starttime=int(time.time())
        time.sleep(10)
