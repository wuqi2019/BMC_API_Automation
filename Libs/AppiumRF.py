from AppiumLibrary import AppiumLibrary
import json
from functools import wraps

class AppiumRF(AppiumLibrary):
    def __init__(self,element_locator_path):
        super().__init__()
        with open(element_locator_path,encoding='utf8') as fs:
            self.element_locator=json.load(fs)

    def wait_visible(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            super(AppiumRF, args[0]).wait_until_element_is_visible((args[0])._json_paser(args[1]), timeout=5)
            func(*args, **kwargs)
        return wrapper

    def _json_paser(self,locator):
        locators=locator.split('》')
        result=self.element_locator
        for l in locators:
            result=result[l]
        return result

    def open_application(self, remote_url, alias=None, **kwargs):
        super().open_application(remote_url, alias=None, unicodeKeyboard=True, resetKeyboard=True, **kwargs)
    @wait_visible
    def click_element(self,locator):
        super().click_element(self._json_paser(locator))

    @wait_visible
    def clear_text(self,locator):
        super().clear_text(self._json_paser(locator))

    @wait_visible
    def input_value(self,locator,value):
        super().input_value(self._json_paser(locator),value)

    @wait_visible
    def element_should_be_visible(self, locator, loglevel='INFO'):
        super().element_should_be_visible(self._json_paser(locator),loglevel)

    def element_should_be_visible(self, locator):
        assert (not super().element_should_be_visible(self._json_paser(locator)))

    def element_should_not_contain_text(self, locator, text):
        super().element_should_not_contain_text(self._json_paser(locator), text)

    @wait_visible
    def get_text(self, locator):
        return super().get_text(self._json_paser(locator))

    def clear_and_intput(self, locator, value):
        self.clear_text(locator)
        self.input_value(locator,value)

    def visible_or_not(self,locator):
        try:
            self._element_find(self._json_paser(locator),True,True)
        except:
            return False
        return True
    def wait_until_element_is_visible(self, locator, timeout=None, error=None):
        super().wait_until_element_is_visible(self._json_paser(locator),timeout = timeout,error = error)

    @wait_visible
    def input_text(self, locator, text):
        super().input_text(self._json_paser(locator), text)
if __name__=="__main__":
    rf=AppiumRF("../Resources/Android元素定位器")