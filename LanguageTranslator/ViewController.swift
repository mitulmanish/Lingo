//
//  ViewController.swift
//  LanguageTranslator
//
//  Created by Mitul Manish on 4/10/2016.
//  Copyright © 2016 Mitul Manish. All rights reserved.
//

import UIKit
import Alamofire
import Eureka

struct Language {
    let code: String
    let name: String
}

class ViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var languageList: [Language]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        languageList = [Language(code: "en", name: "English"), Language(code: "es", name: "Spanish"),
                        Language(code: "fr", name: "French"),
                        Language(code: "de", name: "German"),
        Language(code: "it", name: "Italian"), Language(code: "pt", name: "Portuguese")]
        setUpForm()
    }
    
    private func setUpForm() {
        form
            +++ Section("From")
            <<< TextAreaRow("from") { row in
                row.placeholder = "Text to translate"
                row.textAreaHeight = .Dynamic(initialTextViewHeight: 150)
            }
            
            <<< AlertRow<String>("languageFrom") { row in
                for language in self.languageList! {
                    row.options.append(language.name)
                }
                row.title = "From"
                row.selectorTitle = "Select Language"
                row.value = self.languageList?.first?.name
            }
            
            <<< AlertRow<String>("languageTo") { row in
                for language in self.languageList! {
                    row.options.append(language.name)
                }
                row.title = "To"
                row.selectorTitle = "Select Language"
                row.value = self.languageList?.first?.name
            }
            
            +++ Section("To")
            <<< TextAreaRow("to") { row in
                row.placeholder = "Translated text"
                row.textAreaHeight = .Dynamic(initialTextViewHeight: 150)
        }
    }
    
    private func fetchFormValues() -> [String: String] {
        var params: [String: String] = [:]
        let formValues = form.values()
        print(formValues)
        
        
        if let translateFromText = formValues["from"] as? String {
            params["from"] = translateFromText
            print(translateFromText)
        }
        
        if let languageFrom = formValues["languageFrom"] as? String {
            params["languageFrom"] = languageFrom
            print(languageFrom)
        }
        
        if let languageTo = formValues["languageTo"] as? String {
            params["languageTo"] = languageTo
            print(languageTo)
        }
        return params
    }
    
    @IBAction func translateAction(sender: UIBarButtonItem) {
        let params = fetchFormValues()
        
        var finalParams: [String: String] = [:]
        
        finalParams["source"] = extractLanguageCodeFromLanguageName(params["languageFrom"]!)
        finalParams["target"] = extractLanguageCodeFromLanguageName(params["languageTo"]!)
        finalParams["text"] = params["from"]
        
        if let translatedTextArea = form.rowByTag("to") {
            translateWithAlomafire(finalParams) { (text) in
                translatedTextArea.baseValue = text
                translatedTextArea.updateCell()
            }
        }
        
    }
    
    private func extractLanguageCodeFromLanguageName(name: String) -> String? {
        print("inside")
        print(name)
        for language in self.languageList! {
            if name == language.name {
                return language.code
            }
        }
        return nil
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func translateWithAlomafire(params: [String: AnyObject], completionHandler: (String) -> ()) {
        
        let userName = "45d63e99-1693-4c05-9f36-d8353a4d548d"
        let password = "WYcXWEUpVBWR"
        let credentialData = "\(userName):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions([])
        let headers = ["Authorization": "Basic \(base64Credentials)", "Content-type": "application/json", "Accept": "application/json"]
        Alamofire.request(.POST, "https://gateway.watsonplatform.net/language-translator/api/v2/translate",parameters: params,headers: headers, encoding: .JSON).response { (request, response, data, error) in
            do {
                let serverData = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as? [String: AnyObject]
                if let data = serverData {
                    if let translations = data["translations"] as? [[String: AnyObject]] {
                        
                        if let translationDictionary = translations.first {
                            if let translatedText = translationDictionary["translation"] as? String {
                                completionHandler(translatedText)
                            }
                        }
                    } else {
                        print("Can't Cast")
                    }
                }
            } catch {
                
            }
        }
    }
}

