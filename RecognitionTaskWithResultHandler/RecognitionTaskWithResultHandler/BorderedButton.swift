//
//  BorderedButton.swift
//  SFQuota
//
//  Created by Yuske Fukuyama on 2018/07/10.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

class BorderedButton: UIButton {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    sharedInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    sharedInit()
  }
  
  fileprivate func sharedInit() {
    titleLabel?.font = UIFont.systemFont(ofSize: 16)
    contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    layer.borderWidth = 1
    layer.cornerRadius = 5
    isEnabled = false
  }
  
  override var isEnabled: Bool {
    didSet {
      layer.borderColor = (isEnabled ? UIColor.blue : UIColor.gray).cgColor
    }
  }
}
