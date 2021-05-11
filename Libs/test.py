class test:
    def wait_visible(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            super(AppiumRF, args[0]).wait_until_element_is_visible((args[0])._json_paser(args[1]), timeout=5)
            func(*args, **kwargs)

        return wrapper